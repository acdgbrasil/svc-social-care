import Foundation
import Testing
import Vapor
import VaporTesting
@testable import social_care_s

/// Gaps **G12/G13/G14** — a borda HTTP exercitada ponta a ponta.
///
/// Os três middlewares novos (correlação, CORS, rate limit) só provam alguma
/// coisa dentro da cadeia real: o que se afirma aqui é o efeito observável pelo
/// cliente — o header que volta, o 429 no formato de erro do serviço, o
/// preflight que passa sem token — e não a implementação de cada um.
///
/// A ordem de registro em `HTTPTestApp` é a de `configure.swift` de propósito
/// (ADR-044/045/046): trocá-la muda o resultado destes testes.
@Suite("G12/G13/G14 — middlewares de borda")
struct EdgeMiddlewareIntegrationTests {

    // MARK: - G12 — correlação (ADR-044)

    @Test("Toda resposta volta com X-Request-Id, mesmo sem o cliente mandar")
    func responseAlwaysCarriesRequestId() async throws {
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/health") { res async in
                let id = res.headers.first(name: "X-Request-Id")
                #expect(id?.isEmpty == false)
            }
        }
    }

    @Test("X-Request-Id do chamador é preservado — a correlação atravessa os serviços")
    func callerRequestIdIsEchoed() async throws {
        try await HTTPTestApp.withApp { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: "X-Request-Id", value: "bff-01HZX9K3QF")
            try await app.testing().test(.GET, "/health", headers: headers) { res async in
                #expect(res.headers.first(name: "X-Request-Id") == "bff-01HZX9K3QF")
            }
        }
    }

    @Test("X-Request-Id com quebra de linha é descartado — não se injeta linha no log")
    func hostileRequestIdIsReplaced() async throws {
        try await HTTPTestApp.withApp { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: "X-Request-Id", value: "ok id com espaço e | pipe")
            try await app.testing().test(.GET, "/health", headers: headers) { res async in
                let id = res.headers.first(name: "X-Request-Id")
                #expect(id != nil)
                #expect(id != "ok id com espaço e | pipe")
            }
        }
    }

    @Test("traceparent do W3C vira o request id quando não há X-Request-Id")
    func traceparentBecomesRequestId() async throws {
        try await HTTPTestApp.withApp { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(
                name: "traceparent",
                value: "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
            )
            try await app.testing().test(.GET, "/health", headers: headers) { res async in
                #expect(res.headers.first(name: "X-Request-Id") == "4bf92f3577b34da6a3ce929d0e0e4736")
            }
        }
    }

    @Test("Resposta de erro (401) também volta correlacionada")
    func errorResponseIsCorrelated() async throws {
        // O middleware é mais externo que o `AppErrorMiddleware` justamente
        // para isto: sem correlação no erro, o log do incidente não fecha com o
        // que o cliente viu.
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .unauthorized)
                #expect(res.headers.first(name: "X-Request-Id")?.isEmpty == false)
            }
        }
    }

    // MARK: - G13 — CORS (ADR-045)

    @Test("Sem CORS_ALLOWED_ORIGINS o serviço não emite header de CORS")
    func corsIsOptIn() async throws {
        try await HTTPTestApp.withApp { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .origin, value: "https://app.acdgbrasil.com.br")
            try await app.testing().test(.GET, "/health", headers: headers) { res async in
                #expect(res.headers.first(name: .accessControlAllowOrigin) == nil)
            }
        }
    }

    @Test("Origem na allowlist recebe Access-Control-Allow-Origin")
    func allowedOriginIsEchoed() async throws {
        let cors = try #require(
            try CORSPolicy.configuration(
                originsCSV: "https://app.acdgbrasil.com.br",
                isProduction: true
            )
        )
        try await HTTPTestApp.withApp(cors: cors) { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .origin, value: "https://app.acdgbrasil.com.br")
            try await app.testing().test(.GET, "/health", headers: headers) { res async in
                #expect(res.headers.first(name: .accessControlAllowOrigin) == "https://app.acdgbrasil.com.br")
                // O cliente precisa enxergar a correlação e a cota.
                let exposed = (res.headers.first(name: .accessControlExpose) ?? "").lowercased()
                #expect(exposed.contains("x-request-id"))
                #expect(exposed.contains("x-ratelimit-remaining"))
            }
        }
    }

    @Test("Origem fora da allowlist não recebe Access-Control-Allow-Origin")
    func foreignOriginIsNotAllowed() async throws {
        let cors = try #require(
            try CORSPolicy.configuration(
                originsCSV: "https://app.acdgbrasil.com.br",
                isProduction: true
            )
        )
        try await HTTPTestApp.withApp(cors: cors) { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .origin, value: "https://site-invasor.example.com")
            try await app.testing().test(.GET, "/health", headers: headers) { res async in
                #expect(res.headers.first(name: .accessControlAllowOrigin) == nil)
            }
        }
    }

    @Test("Preflight OPTIONS responde sem token — o navegador não manda Authorization nele")
    func preflightDoesNotRequireToken() async throws {
        // Se o CORS ficasse depois do JWTAuth, todo preflight tomaria 401 e o
        // navegador nem chegaria a mandar a requisição real.
        let cors = try #require(
            try CORSPolicy.configuration(
                originsCSV: "https://app.acdgbrasil.com.br",
                isProduction: true
            )
        )
        try await HTTPTestApp.withApp(cors: cors) { app in
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .origin, value: "https://app.acdgbrasil.com.br")
            headers.replaceOrAdd(name: .accessControlRequestMethod, value: "GET")
            try await app.testing().test(.OPTIONS, "/api/v1/patients", headers: headers) { res async in
                #expect(res.status == .ok)
                #expect(res.headers.first(name: .accessControlAllowOrigin) == "https://app.acdgbrasil.com.br")
            }
        }
    }

    // MARK: - G14 — rate limit (ADR-046)

    @Test("Estourado o teto, a requisição seguinte é 429 no formato de erro do serviço")
    func exceedingTheLimitYields429() async throws {
        try await HTTPTestApp.withApp(rateLimit: RateLimitConfiguration(limit: 2, window: 60)) { app in
            let tester = try app.testing()
            try await tester.test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .unauthorized)   // 1º crédito
            }
            try await tester.test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .unauthorized)   // 2º crédito
            }
            try await tester.test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .tooManyRequests)
                // Mesmo envelope de erro do resto do serviço — contrato do BFF.
                #expect(res.body.string.contains("HTTP-429"))
                // Sem Retry-After o cliente só sabe que falhou, não quando voltar.
                #expect(res.headers.first(name: .retryAfter) != nil)
                #expect(res.headers.first(name: "X-RateLimit-Limit") == "2")
            }
        }
    }

    @Test("Resposta permitida informa a cota restante")
    func allowedResponseCarriesQuota() async throws {
        try await HTTPTestApp.withApp(rateLimit: RateLimitConfiguration(limit: 10, window: 60)) { app in
            let token = try await HTTPTestApp.token(roles: ["worker"])
            try await app.testing().test(.GET, "/api/v1/patients", headers: .bearer(token)) { res async in
                #expect(res.status == .ok)
                #expect(res.headers.first(name: "X-RateLimit-Limit") == "10")
                #expect(res.headers.first(name: "X-RateLimit-Remaining") == "9")
                #expect(res.headers.first(name: "X-RateLimit-Reset") != nil)
            }
        }
    }

    @Test("Resposta de erro também informa a cota — quem queima crédito em 401 precisa saber")
    func errorResponseCarriesQuota() async throws {
        // O limitador fica por fora do AppErrorMiddleware justamente para isto:
        // ali a resposta de erro já existe e pode receber a cota.
        try await HTTPTestApp.withApp(rateLimit: RateLimitConfiguration(limit: 10, window: 60)) { app in
            try await app.testing().test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .unauthorized)
                #expect(res.headers.first(name: "X-RateLimit-Remaining") == "9")
            }
        }
    }

    @Test("Probe do orquestrador é isenta — /health não toma 429")
    func probesAreExempt() async throws {
        // Rate limit que atinge o kubelet derruba o pod saudável: o liveness
        // falha, o orquestrador reinicia, e o serviço fica pior sob carga.
        try await HTTPTestApp.withApp(rateLimit: RateLimitConfiguration(limit: 1, window: 60)) { app in
            let tester = try app.testing()
            for _ in 1...5 {
                try await tester.test(.GET, "/health") { res async in
                    #expect(res.status == .ok)
                }
            }
        }
    }

    @Test("Sem rate limit configurado, nenhuma resposta carrega cota")
    func disabledRateLimitAddsNoHeaders() async throws {
        try await HTTPTestApp.withApp(rateLimit: nil) { app in
            try await app.testing().test(.GET, "/health") { res async in
                #expect(res.headers.first(name: "X-RateLimit-Limit") == nil)
            }
        }
    }
}
