import Foundation
import JWT
import Testing
@testable import social_care_s

/// Teste de regressão do **ADR-040** (refresh de JWKS em runtime): garante que o
/// `JWKSRefresher` — periódico + on-demand por `kid` — funciona conforme o
/// contrato, usando fakes (sem rede, sem IdP, sem tempo real).
///
/// Cobre a seção "Teste de regressão" do ADR-040:
/// - `refresh()` re-aplica o JWKS no key store e atualiza `knownKids`.
/// - `refreshIfKidUnknown(kidNovo)` **dispara** refresh (kid desconhecido, fora
///   do cooldown) e retorna `true`.
/// - `refreshIfKidUnknown(kidConhecido)` **não** dispara (retorna `false`).
/// - `refreshIfKidUnknown` dentro do **cooldown** **não** dispara
///   (anti-hammering), usando clock injetável (ADR-034).
@Suite("JWKSRefresher — refresh periódico + on-demand por kid (ADR-040)")
struct JWKSRefreshTest {

    // MARK: - Helpers

    /// JWKS mínimo válido (decodificável por `JWKS` do JWTKit) com os `kid`
    /// informados. Os campos `n`/`e` são placeholders — `extractKids` só lê `kid`.
    private func jwks(kids: [String]) -> String {
        let keys = kids
            .map { #"{"kty":"RSA","kid":"\#($0)","n":"AQAB","e":"AQAB"}"# }
            .joined(separator: ",")
        return #"{"keys":[\#(keys)]}"#
    }

    private func makeRefresher(
        jwks: String,
        interval: TimeInterval = 600,
        cooldown: TimeInterval = 30,
        now: @escaping @Sendable () -> Date = { Date() }
    ) -> (JWKSRefresher, FakeJWKSFetcher, FakeKeyStore) {
        let fetcher = FakeJWKSFetcher(jwks: jwks)
        let store = FakeKeyStore()
        let refresher = JWKSRefresher(
            urls: ["https://idp.example.com/jwks"],
            fetcher: fetcher,
            keyStore: store,
            interval: interval,
            cooldown: cooldown,
            now: now
        )
        return (refresher, fetcher, store)
    }

    // MARK: - refresh()

    @Test("refresh() aplica o JWKS no key store e popula knownKids")
    func refreshPopulatesKnownKids() async throws {
        let (refresher, fetcher, store) = makeRefresher(jwks: jwks(kids: ["kid-1"]))

        try await refresher.refresh()

        #expect(await refresher.knownKids.contains("kid-1"))
        #expect(await fetcher.callCount == 1)
        #expect(await store.addedJSONs.count == 1)
    }

    // MARK: - on-demand: kid desconhecido dispara

    @Test("refreshIfKidUnknown(kidNovo) dispara refresh e retorna true")
    func onDemandUnknownKidTriggers() async throws {
        let (refresher, fetcher, _) = makeRefresher(jwks: jwks(kids: ["kid-new"]))

        let didRefetch = await refresher.refreshIfKidUnknown("kid-new")

        #expect(didRefetch)
        #expect(await fetcher.callCount == 1)
        #expect(await refresher.knownKids.contains("kid-new"))
    }

    // MARK: - on-demand: kid conhecido é no-op

    @Test("refreshIfKidUnknown(kidConhecido) não dispara e retorna false")
    func onDemandKnownKidIsNoop() async throws {
        let (refresher, fetcher, _) = makeRefresher(jwks: jwks(kids: ["kid-1"]))
        try await refresher.refresh() // knownKids = {kid-1}, callCount = 1

        let didRefetch = await refresher.refreshIfKidUnknown("kid-1")

        #expect(!didRefetch)
        #expect(await fetcher.callCount == 1) // não refetchou
    }

    // MARK: - on-demand: cooldown (anti-hammering) via clock injetável

    @Test("refreshIfKidUnknown dentro do cooldown não dispara; fora do cooldown dispara")
    func onDemandRespectsCooldown() async throws {
        let clock = TestClock(start: Date(timeIntervalSince1970: 1_000_000))
        let (refresher, fetcher, _) = makeRefresher(
            jwks: jwks(kids: ["kid-1"]),
            cooldown: 30,
            now: clock.reader
        )
        try await refresher.refresh() // lastRefresh = t0, callCount = 1

        // kid-2 desconhecido, mas 5s < cooldown de 30s → NÃO dispara.
        clock.advance(by: 5)
        let within = await refresher.refreshIfKidUnknown("kid-2")
        #expect(!within)
        #expect(await fetcher.callCount == 1)

        // Avança além do cooldown (total 35s > 30s) → dispara (refetchou → true),
        // mesmo que o JWKS retornado ainda não contenha kid-2.
        clock.advance(by: 30)
        let after = await refresher.refreshIfKidUnknown("kid-2")
        #expect(after)
        #expect(await fetcher.callCount == 2)
    }

    // MARK: - on-demand: falha de fetch é engolida (retorna false)

    @Test("refreshIfKidUnknown retorna false quando o fetch falha (erro engolido)")
    func onDemandSwallowsFetchError() async throws {
        let refresher = JWKSRefresher(
            urls: ["u"],
            fetcher: ThrowingJWKSFetcher(),
            keyStore: FakeKeyStore(),
            cooldown: 0
        )
        let didRefetch = await refresher.refreshIfKidUnknown("kid-x")
        #expect(!didRefetch)
    }

    // MARK: - extractKids (decodifica JWKS do JWTKit)

    @Test("extractKids decodifica múltiplos kids de um JWKS válido")
    func extractKidsMultiple() {
        let kids = JWKSRefresher.extractKids(from: jwks(kids: ["a", "b", "c"]))
        #expect(kids == ["a", "b", "c"])
    }

    @Test("extractKids retorna vazio para JSON inválido ou chave sem kid")
    func extractKidsInvalid() {
        #expect(JWKSRefresher.extractKids(from: "not json at all").isEmpty)
        // JWKS estruturalmente válido, mas a chave não traz `kid` → ignorada.
        #expect(JWKSRefresher.extractKids(from: #"{"keys":[{"kty":"RSA","n":"AQAB","e":"AQAB"}]}"#).isEmpty)
    }

    // MARK: - seedKnownKids (semente do boot)

    @Test("seedKnownKids semeia knownKids a partir de múltiplos JWKS")
    func seedFromMultipleJWKS() async {
        let (refresher, _, _) = makeRefresher(jwks: jwks(kids: ["ignored"]))
        await refresher.seedKnownKids(fromJWKS: [jwks(kids: ["k1"]), jwks(kids: ["k2", "k3"])])
        #expect(await refresher.knownKids == ["k1", "k2", "k3"])
    }

    // MARK: - key store real (JWTKeyCollection.addJWKS via extension)

    @Test("refresh aplica JWKS num JWTKeyCollection real via extension addJWKS")
    func refreshAppliesToRealKeyCollection() async throws {
        let keys = JWTKeyCollection()
        let fetcher = FakeJWKSFetcher(jwks: #"{"keys":[]}"#) // JWKS vazio: exercita a extension sem exigir chave RSA real
        let refresher = JWKSRefresher(urls: ["u"], fetcher: fetcher, keyStore: keys)
        try await refresher.refresh() // não deve lançar
        #expect(await fetcher.callCount == 1)
    }

    /// **O cenário que motiva o ADR-040**, ponta a ponta com key store real: o IdP
    /// rotaciona a chave, o serviço recebe um token com `kid` que não conhece e,
    /// depois do refresh, passa a aceitar **o mesmo token**. É a prova de que a
    /// feature elimina o 401-em-massa pós-rotação — os demais testes exercitam as
    /// partes (fetch, cooldown, hook do middleware) sem fechar este ciclo.
    ///
    /// Usa ECDSA P-256 porque o JWTKit só materializa JWK de `kty` RSA/EC/OKP
    /// (não há `oct`/HMAC em JWKS). A chave é gerada no próprio teste — nenhum
    /// material criptográfico fica no repo.
    @Test("rotação de chave: após o refresh, o key store real aceita o token novo")
    func rotationMakesRealKeyStoreAcceptNewToken() async throws {
        // Chave que o IdP passa a usar depois de rotacionar.
        let rotatedKey = ES256PrivateKey()
        let params = try #require(rotatedKey.parameters) // x/y já em base64url
        let jwksAfterRotation = #"""
        {"keys":[{"kty":"EC","crv":"P-256","alg":"ES256","kid":"rotated","x":"\#(params.x)","y":"\#(params.y)"}]}
        """#

        // Token emitido pelo IdP com a chave nova.
        let idpKeys = JWTKeyCollection()
        await idpKeys.add(ecdsa: rotatedKey, kid: "rotated")
        let token = try await idpKeys.sign(RotationProbePayload(), kid: "rotated")

        // Store do serviço: o que o boot carregou — ainda sem a chave nova.
        let serviceKeys = JWTKeyCollection()
        await #expect(throws: (any Error).self) {
            _ = try await serviceKeys.verify(token, as: RotationProbePayload.self)
        }

        // On-demand: `kid` desconhecido → refresh → upsert no store real.
        let refresher = JWKSRefresher(
            urls: ["https://idp.example.com/jwks"],
            fetcher: FakeJWKSFetcher(jwks: jwksAfterRotation),
            keyStore: serviceKeys
        )
        #expect(await refresher.refreshIfKidUnknown("rotated"))
        #expect(await refresher.knownKids.contains("rotated"))

        // O MESMO token agora é aceito — sem restart.
        let verified = try await serviceKeys.verify(token, as: RotationProbePayload.self)
        #expect(verified.marker == "rotated-ok")
    }

    // MARK: - runPeriodic (loop + cancelamento)

    @Test("runPeriodic executa ao menos um ciclo e encerra no cancelamento")
    func runPeriodicTicksThenCancels() async throws {
        let fetcher = FakeJWKSFetcher(jwks: jwks(kids: ["kid-1"]))
        let store = FakeKeyStore()
        let refresher = JWKSRefresher(
            urls: ["u"],
            fetcher: fetcher,
            keyStore: store,
            interval: 0.02,
            cooldown: 0
        )
        let task = Task { await refresher.runPeriodic() }

        // Aguarda ao menos um ciclo (deadline de ~1s para nunca travar).
        var waited = 0
        while await fetcher.callCount < 1, waited < 200 {
            try await Task.sleep(for: .milliseconds(5))
            waited += 1
        }
        #expect(await fetcher.callCount >= 1)

        task.cancel()
        await task.value // runPeriodic retorna no cancelamento (sem hang)
        #expect(await refresher.knownKids.contains("kid-1"))
    }
}

/// Payload mínimo usado só para provar que a assinatura passa a ser aceita após
/// a rotação. **Não** usa `OIDCJWTPayload` de propósito: o `verify(using:)`
/// daquele consulta o singleton global `OIDCJWTPayloadBootstrap.shared`, e este
/// teste não deve depender de estado compartilhado entre suites (mesma razão
/// documentada no topo de `JWKSRuntimeRefreshIntegrationTests`).
struct RotationProbePayload: JWTPayload {
    var marker = "rotated-ok"
    func verify(using _: some JWTAlgorithm) async throws {}
}

/// Fake de `JWKSFetching` que sempre falha — exercita o caminho de erro do
/// refresher (fetch lança → `refreshIfKidUnknown` engole e retorna false).
struct ThrowingJWKSFetcher: JWKSFetching {
    struct Boom: Error {}
    func fetch(url _: String) async throws -> String {
        throw Boom()
    }
}

// MARK: - Test Doubles

/// Fake do port `JWKSFetching`: conta chamadas e devolve um JWKS controlado.
/// `actor` para ser `Sendable` e contar chamadas sem data race.
actor FakeJWKSFetcher: JWKSFetching {
    private(set) var callCount = 0
    private var jwksToReturn: String

    init(jwks: String) {
        self.jwksToReturn = jwks
    }

    func fetch(url _: String) async throws -> String {
        callCount += 1
        return jwksToReturn
    }

    /// Permite trocar o JWKS retornado entre chamadas (simula rotação do IdP).
    func setJWKS(_ json: String) {
        jwksToReturn = json
    }
}

/// Fake do port `JWKSKeyStore`: registra os JSONs aplicados (para asserts),
/// sem tocar num `JWTKeyCollection` real.
actor FakeKeyStore: JWKSKeyStore {
    private(set) var addedJSONs: [String] = []

    func addJWKS(json: String) async throws {
        addedJSONs.append(json)
    }
}

/// Clock de teste com tempo controlado manualmente — permite exercitar o
/// cooldown do refresher sem `sleep` real (ADR-034: clock injetável).
/// `@unchecked Sendable`: estado protegido por `NSLock`.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(start: Date) {
        self.current = start
    }

    /// Closure `@Sendable` para injetar como `now` no refresher.
    var reader: @Sendable () -> Date {
        { [self] in
            lock.lock()
            defer { lock.unlock() }
            return current
        }
    }

    func advance(by seconds: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }
}
