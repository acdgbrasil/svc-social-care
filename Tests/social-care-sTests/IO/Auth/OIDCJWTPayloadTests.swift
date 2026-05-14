import Foundation
import JWT
import Testing
@testable import social_care_s

/// Tests para `OIDCJWTPayload` — multi-issuer (Authentik atual + Zitadel legado
/// durante migração, ADR-027/031). Cobre derivação de roles a partir de:
/// - `roles` claim (Authentik com property mapping `acdg-roles` — ADR-029)
/// - `groups` claim (Authentik default)
/// - `urn:zitadel:iam:org:project:roles` (Zitadel legado, durante migracao)
///
/// Audit trail (ADR-023) preservado: `sub` continua sendo o actorId.
/// Claims adicionais: `org_id`, `person_id`, `legacy_sub` (ADR-031).
@Suite("OIDCJWTPayload — multi-issuer (Authentik + Zitadel legado)")
struct OIDCJWTPayloadTests {

    // MARK: - Helpers

    /// Encoder/decoder via JSON round-trip (preserva CodingKeys do Codable).
    private func decode(_ json: String) throws -> OIDCJWTPayload {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(OIDCJWTPayload.self, from: data)
    }

    private let expFuture = Int(Date(timeIntervalSinceNow: 3600).timeIntervalSince1970)
    private let expPast = Int(Date(timeIntervalSinceNow: -3600).timeIntervalSince1970)

    // MARK: - Authentik shape (default — `groups` claim)

    @Test("Authentik default: derive roles do claim 'groups'")
    func authentikGroups() throws {
        let json = """
        {
          "sub": "fe025d9c8429d445f0d18e2380c17ec5",
          "iss": "http://authentik:9000/application/o/social-care/",
          "aud": "OBEiWNx12lS0KTDXPmDgcm6AwpmlY4MtiQcpaeLc",
          "exp": \(expFuture),
          "groups": ["social_worker", "social-care:admin"]
        }
        """
        let payload = try decode(json)
        #expect(payload.roleNames == ["social_worker", "social-care:admin"])
        #expect(payload.sub.value == "fe025d9c8429d445f0d18e2380c17ec5")
    }

    // MARK: - Authentik shape (com property mapping `acdg-roles` — ADR-029)

    @Test("Authentik com acdg-roles: derive roles + org_id + person_id + legacy_sub")
    func authentikAcdgRolesMapping() throws {
        let json = """
        {
          "sub": "fe025d9c8429d445f0d18e2380c17ec5",
          "iss": "http://authentik:9000/application/o/social-care/",
          "aud": "OBEiWNx12lS0KTDXPmDgcm6AwpmlY4MtiQcpaeLc",
          "exp": \(expFuture),
          "roles": ["social-care:admin", "social_worker"],
          "org_id": "acdg-default",
          "person_id": "01HXYABCDEF",
          "legacy_sub": "270366461930766336"
        }
        """
        let payload = try decode(json)
        #expect(payload.roleNames == ["social-care:admin", "social_worker"])
        #expect(payload.orgId == "acdg-default")
        #expect(payload.personId == "01HXYABCDEF")
        #expect(payload.legacySub == "270366461930766336")
    }

    @Test("`roles` claim tem precedencia sobre `groups` (ADR-029 property mapping ativa)")
    func rolesTakesPrecedenceOverGroups() throws {
        let json = """
        {
          "sub": "abc", "iss": "http://x/", "aud": "y", "exp": \(expFuture),
          "roles": ["from-roles"],
          "groups": ["from-groups"]
        }
        """
        let payload = try decode(json)
        #expect(payload.roleNames == ["from-roles"])
    }

    // MARK: - Zitadel legado (durante migracao Sprint 3-4 — multi-issuer)

    @Test("Zitadel legado: derive roles do claim `urn:zitadel:iam:org:project:roles`")
    func zitadelLegacyProjectRoles() throws {
        let json = """
        {
          "sub": "270366461930766336",
          "iss": "https://auth.acdgbrasil.com.br",
          "aud": "270366461930766336@social-care",
          "exp": \(expFuture),
          "urn:zitadel:iam:org:project:roles": {
            "social_worker": {"270366000000000000": "acdg.org"},
            "social-care:admin": {"270366000000000000": "acdg.org"}
          }
        }
        """
        let payload = try decode(json)
        #expect(payload.roleNames == ["social_worker", "social-care:admin"])
    }

    // MARK: - Edge cases

    @Test("Token sem nenhum claim de roles tem roleNames vazio")
    func emptyRoles() throws {
        let json = """
        {"sub": "a", "iss": "http://x/", "aud": "y", "exp": \(expFuture)}
        """
        let payload = try decode(json)
        #expect(payload.roleNames.isEmpty)
    }

    @Test("Token sem org_id retorna nil (sem fallback aqui — fallback fica em AuthenticatedUser)")
    func missingOrgIdReturnsNil() throws {
        let json = """
        {"sub": "a", "iss": "http://x/", "aud": "y", "exp": \(expFuture)}
        """
        let payload = try decode(json)
        #expect(payload.orgId == nil)
    }

    // MARK: - verify(): issuer validation (multi-issuer)

    @Test("verify aceita issuer presente na lista OIDC_ISSUERS")
    func verifyAcceptsListedIssuer() async throws {
        let json = """
        {
          "sub": "a",
          "iss": "http://authentik:9000/application/o/social-care/",
          "aud": "client-id-x",
          "exp": \(expFuture)
        }
        """
        let payload = try decode(json)
        // Stub multi-issuer + multi-audience
        let validators = OIDCJWTValidators(
            allowedIssuers: [
                "https://auth.acdgbrasil.com.br",
                "http://authentik:9000/application/o/social-care/"
            ],
            allowedAudiences: ["client-id-x", "270366461930766336@social-care"]
        )
        try await payload.verify(validators: validators)
    }

    @Test("verify rejeita issuer fora da lista (JWTError.claimVerificationFailure)")
    func verifyRejectsUnknownIssuer() async throws {
        let json = """
        {"sub": "a", "iss": "https://malicious.example.com", "aud": "y", "exp": \(expFuture)}
        """
        let payload = try decode(json)
        let validators = OIDCJWTValidators(
            allowedIssuers: ["https://auth.acdgbrasil.com.br"],
            allowedAudiences: ["y"]
        )
        await #expect(throws: JWTError.self) {
            try await payload.verify(validators: validators)
        }
    }

    @Test("verify rejeita audience fora da lista")
    func verifyRejectsUnknownAudience() async throws {
        let json = """
        {"sub": "a", "iss": "https://auth.acdgbrasil.com.br", "aud": "wrong-aud", "exp": \(expFuture)}
        """
        let payload = try decode(json)
        let validators = OIDCJWTValidators(
            allowedIssuers: ["https://auth.acdgbrasil.com.br"],
            allowedAudiences: ["expected-aud"]
        )
        await #expect(throws: JWTError.self) {
            try await payload.verify(validators: validators)
        }
    }

    @Test("verify rejeita token expirado")
    func verifyRejectsExpiredToken() async throws {
        let json = """
        {"sub": "a", "iss": "https://auth.acdgbrasil.com.br", "aud": "y", "exp": \(expPast)}
        """
        let payload = try decode(json)
        let validators = OIDCJWTValidators(
            allowedIssuers: ["https://auth.acdgbrasil.com.br"],
            allowedAudiences: ["y"]
        )
        await #expect(throws: JWTError.self) {
            try await payload.verify(validators: validators)
        }
    }

    // MARK: - Multi-audience: aud como array

    @Test("verify aceita aud como array com pelo menos um valor da lista")
    func verifyAcceptsAudArrayIntersect() async throws {
        let json = """
        {
          "sub": "a",
          "iss": "https://auth.acdgbrasil.com.br",
          "aud": ["aud-1", "aud-2"],
          "exp": \(expFuture)
        }
        """
        let payload = try decode(json)
        let validators = OIDCJWTValidators(
            allowedIssuers: ["https://auth.acdgbrasil.com.br"],
            allowedAudiences: ["aud-2", "aud-3"]
        )
        try await payload.verify(validators: validators)
    }

    // MARK: - OIDCJWTValidators (factory a partir de env)

    @Test("OIDCJWTValidators.fromValues: divide CSV por virgula com trim")
    func validatorsFromCsv() throws {
        let validators = try #require(OIDCJWTValidators.fromValues(
            issuersCsv: "https://a.example.com, https://b.example.com ,https://c.example.com",
            audiencesCsv: "aud1,aud2"
        ))
        #expect(validators.allowedIssuers == [
            "https://a.example.com",
            "https://b.example.com",
            "https://c.example.com"
        ])
        #expect(validators.allowedAudiences == ["aud1", "aud2"])
    }

    @Test("OIDCJWTValidators.fromValues: rejeita lista vazia (fail-fast no boot)")
    func validatorsRejectsEmpty() {
        #expect(OIDCJWTValidators.fromValues(issuersCsv: "", audiencesCsv: "y") == nil)
        #expect(OIDCJWTValidators.fromValues(issuersCsv: "x", audiencesCsv: "") == nil)
    }

    // MARK: - AppSec CRITICAL-1 (review 2026-05-14): defense-in-depth

    @Test("verify(using:) consulta storage global e valida iss/aud sem segunda passada manual")
    func verifyUsingConsultsGlobalBootstrap() async throws {
        defer { OIDCJWTPayloadBootstrap.shared.reset() }
        let validators = try #require(OIDCJWTValidators.fromValues(
            issuersCsv: "https://auth.acdgbrasil.com.br",
            audiencesCsv: "expected-aud"
        ))
        OIDCJWTPayloadBootstrap.shared.set(validators)

        let json = """
        {"sub":"a","iss":"https://auth.acdgbrasil.com.br","aud":"expected-aud","exp":\(expFuture)}
        """
        let payload = try decode(json)
        try await payload.verify(using: TestAlgorithm())
    }

    @Test("verify(using:) FALHA se OIDCJWTPayloadBootstrap nao registrado (fail-closed)")
    func verifyUsingFailsClosedWithoutBootstrap() async throws {
        OIDCJWTPayloadBootstrap.shared.reset()
        defer { OIDCJWTPayloadBootstrap.shared.reset() }

        let json = """
        {"sub":"a","iss":"https://auth.acdgbrasil.com.br","aud":"y","exp":\(expFuture)}
        """
        let payload = try decode(json)
        await #expect(throws: JWTError.self) {
            try await payload.verify(using: TestAlgorithm())
        }
    }

    @Test("verify(using:) rejeita issuer fora da whitelist mesmo com signature valida (CRIT-2 mitigation)")
    func verifyUsingRejectsCrossIssuer() async throws {
        defer { OIDCJWTPayloadBootstrap.shared.reset() }
        OIDCJWTPayloadBootstrap.shared.set(try #require(OIDCJWTValidators.fromValues(
            issuersCsv: "https://auth.acdgbrasil.com.br",
            audiencesCsv: "y"
        )))

        let json = """
        {"sub":"a","iss":"https://malicious.example.com","aud":"y","exp":\(expFuture)}
        """
        let payload = try decode(json)
        await #expect(throws: JWTError.self) {
            try await payload.verify(using: TestAlgorithm())
        }
    }

    // MARK: - AppSec HIGH-A: nbf (not-before) validation

    @Test("verify rejeita token com nbf no futuro")
    func verifyRejectsNbfFuture() async throws {
        let json = """
        {"sub":"a","iss":"https://auth.acdgbrasil.com.br","aud":"y",
         "exp":\(expFuture),"nbf":\(expFuture - 10)}
        """
        let payload = try decode(json)
        let validators = try #require(OIDCJWTValidators.fromValues(
            issuersCsv: "https://auth.acdgbrasil.com.br",
            audiencesCsv: "y"
        ))
        // nbf no passado relativo a expFuture mas pode ser futuro relativo a now
        // Vou criar caso garantido de nbf futuro:
        let jsonNbfFuture = """
        {"sub":"a","iss":"https://auth.acdgbrasil.com.br","aud":"y",
         "exp":\(expFuture),"nbf":\(Int(Date(timeIntervalSinceNow: 3500).timeIntervalSince1970))}
        """
        let payloadNbfFuture = try decode(jsonNbfFuture)
        await #expect(throws: JWTError.self) {
            try await payloadNbfFuture.verify(validators: validators)
        }
        // Token sem nbf passa
        let jsonNoNbf = """
        {"sub":"a","iss":"https://auth.acdgbrasil.com.br","aud":"y","exp":\(expFuture)}
        """
        let payloadNoNbf = try decode(jsonNoNbf)
        try await payloadNoNbf.verify(validators: validators)

        // Suprime warning de "payload nao usado"
        _ = payload
    }

    // MARK: - M5: roles vazio NAO faz fallback para groups

    @Test("M5: roles vazio explicito retorna [] (sem fallback para groups)")
    func emptyRolesDoesNotFallbackToGroups() throws {
        let json = """
        {"sub":"a","iss":"x","aud":"y","exp":\(expFuture),
         "roles":[],"groups":["from-groups"]}
        """
        let payload = try decode(json)
        #expect(payload.roleNames.isEmpty)
    }
}

// Stub minimo de JWTAlgorithm para invocar verify(using:) em tests
// (a verificacao de assinatura ja aconteceu na producao via JWKS keystore).
private struct TestAlgorithm: JWTAlgorithm {
    var name: String { "none" }
    func sign<Plaintext: DataProtocol>(_: Plaintext) throws -> [UInt8] { [] }
    func verify<Signature: DataProtocol, Plaintext: DataProtocol>(
        _: Signature, signs _: Plaintext
    ) throws -> Bool { true }
}
