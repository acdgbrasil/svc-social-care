import Foundation
import Testing
import Vapor
@testable import social_care_s

// gap: G14 — rate limiting
// ADR: ADR-046 — token bucket por cliente, em memória do processo

/// Regressão do **G14 / ADR-046**.
///
/// O limitador é a única defesa do serviço contra requisição em volume: sem ele,
/// varrer `/api/v1/patients/<uuid>` ou martelar o 401 com tokens forjados custa
/// nada para quem ataca. As armadilhas que esta suite fixa:
///
/// 1. **Janela fixa em vez de balde.** Janela fixa deixa passar 2× o limite na
///    virada — o burst do fim de uma janela soma com o do começo da seguinte.
/// 2. **`X-Forwarded-For` confiado por default.** Se qualquer cliente puder
///    falar direto com o serviço, o header é escolha do atacante e o limite
///    deixa de existir.
/// 3. **Probe do orquestrador limitada.** O kubelet bate em intervalo fixo; ele
///    seria o primeiro a tomar 429 e reiniciaria o pod que estava saudável.
/// 4. **Dicionário sem teto.** Uma varredura de origens forjadas viraria
///    consumo de memória ilimitado.
/// 5. **IP inteiro no log.** IP é dado pessoal (LGPD): o log guarda a faixa.
@Suite("Regression: Security — G14 rate limit")
struct RateLimitRegressionTests {

    private func makeLimiter(
        limit: Int,
        window: TimeInterval,
        clock: TestClock,
        maxTrackedKeys: Int = RateLimiter.defaultMaxTrackedKeys
    ) -> RateLimiter {
        RateLimiter(
            configuration: RateLimitConfiguration(limit: limit, window: window),
            now: clock.reader,
            maxTrackedKeys: maxTrackedKeys
        )
    }

    // MARK: - Contagem

    @Test("G14 — o limite é respeitado e o crédito volta com o tempo")
    func test_G14_limit_is_enforced_and_refills() async {
        let clock = TestClock()
        let limiter = makeLimiter(limit: 3, window: 60, clock: clock)

        for expectedRemaining in [2, 1, 0] {
            let decision = await limiter.consume(key: "203.0.113.10")
            #expect(decision.allowed)
            #expect(decision.remaining == expectedRemaining)
        }

        let blocked = await limiter.consume(key: "203.0.113.10")
        #expect(!blocked.allowed)
        #expect(blocked.retryAfterSeconds >= 1,
                "G14: 429 sem Retry-After útil deixa o cliente sem saber quando voltar.")

        // 1 crédito repõe a cada window/limit = 20s.
        clock.advance(by: 20)
        let afterRefill = await limiter.consume(key: "203.0.113.10")
        #expect(afterRefill.allowed)
    }

    @Test("G14 — o crédito repõe gradualmente, não em bloco na virada da janela")
    func test_G14_refill_is_gradual_not_windowed() async {
        // Com janela fixa, esperar o fim da janela devolveria os 4 créditos de
        // uma vez e permitiria 8 requisições em dois segundos consecutivos.
        let clock = TestClock()
        let limiter = makeLimiter(limit: 4, window: 60, clock: clock)

        for _ in 1...4 { _ = await limiter.consume(key: "cliente") }
        #expect(await limiter.consume(key: "cliente").allowed == false)

        clock.advance(by: 15)   // exatamente 1 crédito (60/4)
        #expect(await limiter.consume(key: "cliente").allowed)
        #expect(await limiter.consume(key: "cliente").allowed == false,
                "G14: mais de um crédito voltou em 15s — a reposição deixou de ser proporcional.")
    }

    @Test("G14 — clientes diferentes têm baldes independentes")
    func test_G14_buckets_are_per_client() async {
        let clock = TestClock()
        let limiter = makeLimiter(limit: 1, window: 60, clock: clock)

        #expect(await limiter.consume(key: "203.0.113.10").allowed)
        #expect(await limiter.consume(key: "203.0.113.10").allowed == false)
        #expect(await limiter.consume(key: "198.51.100.7").allowed,
                "G14: um cliente abusivo passou a bloquear todos os outros.")
    }

    // MARK: - Memória

    @Test("G14 — o número de chaves rastreadas tem teto")
    func test_G14_tracked_keys_are_capped() async {
        let clock = TestClock()
        let limiter = makeLimiter(limit: 5, window: 60, clock: clock, maxTrackedKeys: 50)

        for index in 1...200 {
            _ = await limiter.consume(key: "10.0.0.\(index)")
        }
        let tracked = await limiter.trackedKeys
        #expect(tracked <= 50,
                "G14: o dicionário do limitador cresceu para \(tracked) — origens forjadas viram consumo de memória.")
    }

    // MARK: - Identificação do cliente

    @Test("G14 — X-Forwarded-For é ignorado quando não se confia no proxy")
    func test_G14_forwarded_header_ignored_without_trust_proxy() {
        let key = RateLimitMiddleware.clientKey(
            headers: Self.headers(["X-Forwarded-For": "1.2.3.4"]),
            remoteAddress: "198.51.100.7",
            trustProxy: false
        )
        #expect(key == "198.51.100.7",
                "G14: com XFF confiado por default, trocar o header a cada requisição zera o limite.")
    }

    @Test("G14 — com TRUST_PROXY, a chave é o primeiro IP do X-Forwarded-For")
    func test_G14_first_forwarded_ip_is_the_client() {
        // `client, proxy1, proxy2` — o cliente é o primeiro; os demais são a
        // cadeia de proxies e agrupariam usuários distintos no mesmo balde.
        let key = RateLimitMiddleware.clientKey(
            headers: Self.headers(["X-Forwarded-For": "203.0.113.10, 10.0.0.1, 10.0.0.2"]),
            remoteAddress: "10.0.0.2",
            trustProxy: true
        )
        #expect(key == "203.0.113.10")
    }

    @Test("G14 — header forjado que não é endereço não vira chave")
    func test_G14_garbage_forwarded_header_is_discarded() {
        let key = RateLimitMiddleware.clientKey(
            headers: Self.headers(["X-Forwarded-For": "'; DROP TABLE patients; --"]),
            remoteAddress: "198.51.100.7",
            trustProxy: true
        )
        #expect(key == "198.51.100.7")
        #expect(RateLimitMiddleware.validAddress(String(repeating: "1", count: 60)) == nil)
    }

    @Test("G14 — o log guarda a faixa, não o endereço do cliente")
    func test_G14_log_masks_client_address() {
        #expect(RateLimitMiddleware.maskAddress("203.0.113.42") == "203.0.113.0/24")
        #expect(RateLimitMiddleware.maskAddress("2804:d4b:a9ca:1500::1") == "2804:d4b:a9ca::/48")
        #expect(RateLimitMiddleware.maskAddress("unknown") == "unknown")
    }

    // MARK: - Configuração

    @Test("G14 — ligado por default; só desliga quem pede explicitamente")
    func test_G14_enabled_by_default() {
        let env: [String: String] = [:]
        let configuration = RateLimitConfiguration.fromEnvironment { env[$0] }
        #expect(configuration != nil, "G14: serviço público sem teto de requisição é DoS de custo zero.")
        #expect(configuration?.limit == RateLimitConfiguration.defaultLimit)
        #expect(configuration?.trustProxy == false, "G14: confiar no proxy tem de ser escolha, nunca default.")

        let disabled = RateLimitConfiguration.fromEnvironment { ["RATE_LIMIT_ENABLED": "false"][$0] }
        #expect(disabled == nil)
    }

    @Test("G14 — limite e janela vêm do ambiente")
    func test_G14_configuration_from_environment() {
        let env = [
            "RATE_LIMIT_REQUESTS": "42",
            "RATE_LIMIT_WINDOW_SECONDS": "10",
            "TRUST_PROXY": "true"
        ]
        let configuration = RateLimitConfiguration.fromEnvironment { env[$0] }
        #expect(configuration?.limit == 42)
        #expect(configuration?.window == 10)
        #expect(configuration?.trustProxy == true)
    }

    // MARK: - Lint estrutural

    @Test("G14 — o limitador roda ANTES da autenticação")
    func test_G14_runs_before_authentication() {
        // Depois do JWTAuth, o limitador nunca veria a força bruta de token:
        // ela morre no 401 sem nunca consumir crédito.
        let url = URL(fileURLWithPath: "\(#filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/social-care-s/IO/HTTP/Bootstrap/configure.swift")
        let configure = (try? String(contentsOf: url, encoding: .utf8)) ?? ""

        guard let rateLimit = configure.range(of: "RateLimitMiddleware("),
              let appError = configure.range(of: "app.middleware.use(AppErrorMiddleware())"),
              let auth = configure.range(of: "app.middleware.use(JWTAuthMiddleware())") else {
            Issue.record("G14: não foi possível localizar os middlewares em configure.swift")
            return
        }
        #expect(rateLimit.lowerBound < auth.lowerBound,
                "G14: RateLimitMiddleware DEVE ser registrado antes do JWTAuthMiddleware.")
        #expect(rateLimit.lowerBound < appError.lowerBound,
                "G14: RateLimitMiddleware DEVE ficar por fora do AppErrorMiddleware — é o que permite anexar a cota também às respostas de erro.")
    }

    @Test("G14 — o 429 usa o envelope de erro compartilhado, não um formato próprio")
    func test_G14_uses_shared_error_envelope() {
        // Dois formatos de erro parecidos viram dois contratos para o BFF tratar.
        let url = URL(fileURLWithPath: "\(#filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/social-care-s/IO/HTTP/Middleware/RateLimitMiddleware.swift")
        let middleware = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        #expect(middleware.contains("AppErrorMiddleware.errorResponse"),
                "G14: o 429 deixou de usar `AppErrorMiddleware.errorResponse` — o corpo do erro divergiu do resto do serviço.")
    }

    // MARK: - Helper

    private static func headers(_ pairs: [String: String]) -> HTTPHeaders {
        var headers = HTTPHeaders()
        for (name, value) in pairs {
            headers.replaceOrAdd(name: name, value: value)
        }
        return headers
    }
}
