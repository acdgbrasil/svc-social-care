import Foundation
import JWT
import NIOCore
import NIOPosix
import Testing
import Vapor
@testable import social_care_s

/// Testes de integração do ADR-040 que exercitam os pontos que dependem do
/// runtime do Vapor (sem rede real): o `HTTPJWKSFetcher` com um `Client` fake,
/// o `JWKSRefreshScheduler` no lifecycle de uma app de teste, o storage
/// `Application.jwksRefresher`, e o hook on-demand do `JWTAuthMiddleware`.
///
/// **Sem corrida com o singleton global** (`OIDCJWTPayloadBootstrap.shared`):
/// todos os cenários do middleware aqui **falham a verificação de assinatura**
/// (chave ausente/token inválido), que ocorre ANTES de `verify(using:)` — logo
/// o global nunca é consultado e não há dependência do estado compartilhado que
/// o `OIDCJWTPayloadTests` (serializado) muta.
@Suite("JWKS runtime refresh — fetcher HTTP, scheduler e hook do middleware (ADR-040)")
struct JWKSRuntimeRefreshIntegrationTests {

    // MARK: - Helpers

    /// Cria uma app de teste, executa `body` e garante o shutdown (mesmo em erro).
    private func withApp(_ body: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await body(app)
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    private func base64URL(_ raw: String) -> String {
        Data(raw.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - extractKid / decodeBase64URL (puro, sem Application)

    @Test("extractKid retorna o kid de um header JWT válido")
    func extractKidValid() {
        let header = base64URL(#"{"alg":"RS256","kid":"key-42","typ":"JWT"}"#)
        #expect(JWTAuthMiddleware.extractKid(fromToken: "\(header).payloadpart.sigpart") == "key-42")
    }

    @Test("extractKid retorna nil para token ausente")
    func extractKidNilToken() {
        #expect(JWTAuthMiddleware.extractKid(fromToken: nil) == nil)
    }

    @Test("extractKid retorna nil para token com menos de 2 segmentos")
    func extractKidSingleSegment() {
        #expect(JWTAuthMiddleware.extractKid(fromToken: "abc") == nil)
    }

    @Test("extractKid retorna nil quando o header não traz kid")
    func extractKidNoKid() {
        let header = base64URL(#"{"alg":"RS256","typ":"JWT"}"#)
        #expect(JWTAuthMiddleware.extractKid(fromToken: "\(header).payloadpart.sigpart") == nil)
    }

    @Test("extractKid retorna nil quando o header não decodifica como JSON")
    func extractKidNonJsonHeader() {
        let header = base64URL("this is not json")
        #expect(JWTAuthMiddleware.extractKid(fromToken: "\(header).payloadpart.sigpart") == nil)
    }

    // MARK: - HTTPJWKSFetcher (Client fake, sem rede)

    @Test("HTTPJWKSFetcher.fetch retorna o corpo JSON em caso de sucesso")
    func fetcherSuccess() async throws {
        let json = #"{"keys":[{"kty":"RSA","kid":"k","n":"AQAB","e":"AQAB"}]}"#
        let fetcher = HTTPJWKSFetcher(
            client: FakeClient(eventLoop: MultiThreadedEventLoopGroup.singleton.next(), bodyString: json)
        )
        #expect(try await fetcher.fetch(url: "http://idp.example/jwks") == json)
    }

    @Test("HTTPJWKSFetcher.fetch lança quando o corpo é vazio")
    func fetcherEmptyBody() async {
        let fetcher = HTTPJWKSFetcher(
            client: FakeClient(eventLoop: MultiThreadedEventLoopGroup.singleton.next(), bodyString: nil)
        )
        await #expect(throws: (any Error).self) {
            _ = try await fetcher.fetch(url: "http://idp.example/jwks")
        }
    }

    @Test("HTTPJWKSFetcher.fetch lança quando o corpo não é JSON")
    func fetcherNonJson() async {
        let fetcher = HTTPJWKSFetcher(
            client: FakeClient(eventLoop: MultiThreadedEventLoopGroup.singleton.next(), bodyString: "<html>not json</html>")
        )
        await #expect(throws: (any Error).self) {
            _ = try await fetcher.fetch(url: "http://idp.example/jwks")
        }
    }

    // MARK: - JWKSRefreshScheduler + Application.jwksRefresher

    @Test("Scheduler agenda no didBoot e cancela no shutdown; storage acessível")
    func schedulerLifecycle() async throws {
        try await withApp { app in
            let refresher = JWKSRefresher(
                urls: [],
                fetcher: FakeJWKSFetcher(jwks: #"{"keys":[]}"#),
                keyStore: FakeKeyStore(),
                interval: 3600, // longo: a task apenas dorme durante o teste
                cooldown: 30
            )
            app.jwksRefresher = refresher
            #expect(app.jwksRefresher != nil) // getter/setter do storage

            let scheduler = JWKSRefreshScheduler(refresher: refresher, logger: app.logger)
            try scheduler.didBoot(app) // agenda a Task periódica
            scheduler.shutdown(app)    // cancela a Task (sem hang)
        }
    }

    // MARK: - JWTAuthMiddleware: caminhos de 401 (race-free)

    @Test("401 quando oidcValidators não está configurado (fail-closed no topo)")
    func middlewareNoValidators() async throws {
        try await withApp { app in
            let request = Request(application: app, method: .GET, url: "/patients", on: app.eventLoopGroup.next())
            await #expect(throws: (any Error).self) {
                _ = try await JWTAuthMiddleware().respond(to: request, chainingTo: PassthroughResponder())
            }
        }
    }

    @Test("401 quando não há token nem refresher (catch sem on-demand)")
    func middlewareNoToken() async throws {
        try await withApp { app in
            app.oidcValidators = OIDCJWTValidators(allowedIssuers: ["i"], allowedAudiences: ["a"])
            let request = Request(application: app, method: .GET, url: "/patients", on: app.eventLoopGroup.next())
            await #expect(throws: (any Error).self) {
                _ = try await JWTAuthMiddleware().respond(to: request, chainingTo: PassthroughResponder())
            }
        }
    }

    @Test("on-demand: kid desconhecido dispara refresh e retenta (ainda 401 pois a chave não chega)")
    func middlewareOnDemandRetry() async throws {
        try await withApp { app in
            app.oidcValidators = OIDCJWTValidators(allowedIssuers: ["i"], allowedAudiences: ["a"])

            // Token assinado por uma coleção SEPARADA (kid "rotated"); app.jwt.keys
            // fica vazio → o verify falha → catch → extractKid("rotated") →
            // refreshIfKidUnknown dispara refresh (JWKS vazio) → retry ainda falha
            // → 401. Exercita o ramo on-demand inteiro do middleware.
            let signingKeys = JWTKeyCollection()
            await signingKeys.add(
                hmac: "test-only-secret-0123456789-0123456789",
                digestAlgorithm: .sha256,
                kid: "rotated"
            )
            let payload = OIDCJWTPayload(
                sub: SubjectClaim(value: "a"),
                exp: ExpirationClaim(value: Date(timeIntervalSinceNow: 3600)),
                iss: IssuerClaim(value: "i"),
                aud: AudienceClaim(value: ["a"]),
                nbf: nil, roles: nil, groups: nil, projectRoles: nil,
                orgId: nil, personId: nil, legacySub: nil
            )
            let token = try await signingKeys.sign(payload, kid: "rotated")

            app.jwksRefresher = JWKSRefresher(
                urls: ["u"],
                fetcher: FakeJWKSFetcher(jwks: #"{"keys":[]}"#),
                keyStore: app.jwt.keys,
                cooldown: 0
            )

            let request = Request(application: app, method: .GET, url: "/patients", on: app.eventLoopGroup.next())
            request.headers.bearerAuthorization = BearerAuthorization(token: token)

            await #expect(throws: (any Error).self) {
                _ = try await JWTAuthMiddleware().respond(to: request, chainingTo: PassthroughResponder())
            }
        }
    }
}

// MARK: - Test doubles

/// `Client` fake do Vapor: devolve uma resposta canônica (corpo controlado) sem
/// tocar a rede. Usado para exercitar `HTTPJWKSFetcher.fetch`.
struct FakeClient: Client {
    let eventLoop: EventLoop
    let bodyString: String?
    let status: HTTPStatus

    init(eventLoop: EventLoop, bodyString: String?, status: HTTPStatus = .ok) {
        self.eventLoop = eventLoop
        self.bodyString = bodyString
        self.status = status
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        FakeClient(eventLoop: eventLoop, bodyString: bodyString, status: status)
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        let body = bodyString.map { ByteBuffer(string: $0) }
        return eventLoop.makeSucceededFuture(ClientResponse(status: status, headers: [:], body: body))
    }
}

/// Responder de passagem (200) usado como `next` do middleware. Nos testes
/// acima o middleware SEMPRE lança antes de chamar `next`.
struct PassthroughResponder: AsyncResponder {
    func respond(to request: Request) async throws -> Response {
        Response(status: .ok)
    }
}
