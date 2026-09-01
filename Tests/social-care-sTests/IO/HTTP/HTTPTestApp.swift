import Foundation
import JWT
import Vapor
@testable import social_care_s

/// Monta uma `Application` com a **mesma cadeia HTTP de produção** para os
/// testes de integração do gap G10.
///
/// Não dá para reaproveitar `configure(_:)`: ele abre pool PostgreSQL, roda 21
/// migrations, busca JWKS na rede com 10 tentativas de retry e sobe o relay do
/// Outbox. Este helper replica só o que a requisição atravessa — e a ordem dos
/// middlewares é a mesma de `configure.swift` de propósito, porque a ordem *é*
/// a regra sob teste (`SecurityHeadersMiddleware` primeiro para que a resposta
/// de erro também receba os headers — ADR-012).
///
/// A diferença deliberada é a chave: aqui o JWKS é substituído por um HMAC
/// local, então o teste assina os próprios tokens sem IdP. O que se exercita é
/// o pipeline (`verify` → roles → RoleGuard → controller), não o RS256.
enum HTTPTestApp {

    static let issuer = "https://auth.test.acdg.local"
    static let audience = "social-care-test"

    /// HMAC de teste. Não é segredo de produção — o serviço real valida RS256
    /// contra o JWKS do IdP e nunca aceita HMAC.
    private static let hmacSecret = "g10-http-integration-tests-hmac-key-0123456789"

    // MARK: - Ciclo de vida

    /// Sobe a app, entrega ao `body` e derruba — tudo sob o gate do storage
    /// global de validators (ver `OIDCBootstrapGate`).
    static func withApp(
        databaseFailure: (any Error)? = nil,
        _ body: (Application) async throws -> Void
    ) async throws {
        try await OIDCBootstrapGate.withExclusiveAccess {
            let app = try await Application.make(.testing)
            do {
                try await configureForTests(app, databaseFailure: databaseFailure)
                try await body(app)
            } catch {
                try? await app.asyncShutdown()
                throw error
            }
            try await app.asyncShutdown()
        }
    }

    private static func configureForTests(
        _ app: Application,
        databaseFailure: (any Error)?
    ) async throws {
        await app.jwt.keys.add(hmac: .init(stringLiteral: hmacSecret), digestAlgorithm: .sha256)

        let validators = OIDCJWTValidators(
            allowedIssuers: [issuer],
            allowedAudiences: [audience]
        )
        app.oidcValidators = validators
        // ADR-031: `verify(using:)` lê deste storage global em todo codepath.
        OIDCJWTPayloadBootstrap.shared.set(validators)

        // Mesmo teto de produção (ADR-012 / S-C5).
        app.routes.defaultMaxBodySize = "512kb"

        // Ordem idêntica a `configure.swift` — ela é parte do contrato.
        app.middleware.use(SecurityHeadersMiddleware())
        app.middleware.use(AppErrorMiddleware())
        app.middleware.use(JWTAuthMiddleware())

        let db = StubSQLDatabase(
            eventLoop: app.eventLoopGroup.any(),
            failure: databaseFailure
        )
        app.services = ServiceContainer(db: db)

        try app.register(collection: HealthController())
        try app.register(collection: PatientController())
        try app.register(collection: AssessmentController())
        try app.register(collection: ProtectionController())
        try app.register(collection: CareController())
        try app.register(collection: LookupController())
    }

    // MARK: - Tokens

    /// Assina um token com o HMAC de teste.
    ///
    /// Os defaults produzem um token **válido**; cada teste sobrescreve só o
    /// campo que está exercitando (issuer errado, expirado, sem role...).
    static func token(
        roles: [String]? = nil,
        sub: String = "test-actor-sub",
        issuer: String = HTTPTestApp.issuer,
        audience: String = HTTPTestApp.audience,
        expiresIn: TimeInterval = 3600
    ) async throws -> String {
        let keys = JWTKeyCollection()
        await keys.add(hmac: .init(stringLiteral: hmacSecret), digestAlgorithm: .sha256)

        let payload = OIDCJWTPayload(
            sub: .init(value: sub),
            exp: ExpirationClaim(value: Date(timeIntervalSinceNow: expiresIn)),
            iss: .init(value: issuer),
            aud: .init(value: [audience]),
            nbf: nil,
            roles: roles,
            groups: nil,
            projectRoles: nil,
            orgId: nil,
            personId: nil,
            legacySub: nil
        )
        return try await keys.sign(payload)
    }
}

// MARK: - Açúcar para as requisições

extension HTTPHeaders {
    /// `Authorization: Bearer <token>`.
    static func bearer(_ token: String) -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = .init(token: token)
        return headers
    }
}
