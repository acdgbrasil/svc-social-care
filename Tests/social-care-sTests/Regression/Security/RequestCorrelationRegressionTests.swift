import Foundation
import Testing
import Vapor
@testable import social_care_s

// gap: G12 — observabilidade de requisição
// ADR: ADR-044 — correlação e log de acesso na borda HTTP

/// Regressão do **G12 / ADR-044**.
///
/// O que esta suite impede de voltar:
///
/// 1. **Log de acesso com query string.** `GET /api/v1/patients?search=` carrega
///    nome e CPF. Um log de acesso "completo" copia isso para o stack de logs,
///    que não tem o mesmo controle de acesso que o banco — é vazamento de PII
///    pela porta da observabilidade (ADR-017 pelo outro lado).
/// 2. **Correlation id vindo de fora sem allowlist.** `X-Request-Id` é
///    atacante-controlado: `foo\nERROR fake` injeta uma linha inteira no log
///    agregado.
/// 3. **Middleware registrado depois do `AppErrorMiddleware`**, o que deixaria
///    justamente o caminho de erro — o que interessa investigar — sem
///    `request_id`.
@Suite("Regression: Security — G12 correlação de requisição")
struct RequestCorrelationRegressionTests {

    // MARK: - Lint estrutural

    private func projectRoot(file: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: "\(file)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func source(_ relativePath: String) -> String {
        let url = projectRoot().appendingPathComponent(relativePath)
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private var configureSource: String {
        source("Sources/social-care-s/IO/HTTP/Bootstrap/configure.swift")
    }

    @Test("G12 — o middleware de contexto não toca a query string")
    func test_G12_access_log_never_reads_query_string() {
        let middleware = source("Sources/social-care-s/IO/HTTP/Middleware/RequestContextMiddleware.swift")
        #expect(!middleware.isEmpty, "G12: RequestContextMiddleware.swift sumiu — o log de acesso deixou de existir.")

        // `url.query` e `url.string` trariam `?search=<nome ou CPF>` para o log.
        for forbidden in ["url.query", "url.string"] {
            #expect(!middleware.contains(forbidden),
                    "G12: RequestContextMiddleware usa `\(forbidden)` — a query string carrega PII (search por nome/CPF) e não pode entrar no log.")
        }
    }

    @Test("G12 — configure.swift registra o contexto ANTES do AppErrorMiddleware")
    func test_G12_context_runs_before_error_middleware() {
        let source = configureSource
        guard let context = source.range(of: "RequestContextMiddleware"),
              let appError = source.range(of: "AppErrorMiddleware") else {
            Issue.record("G12: não foi possível localizar os middlewares em configure.swift")
            return
        }
        #expect(context.lowerBound < appError.lowerBound,
                "G12: RequestContextMiddleware DEVE ser registrado antes do AppErrorMiddleware — senão a resposta de erro sai sem X-Request-Id e o log do incidente não fecha com o que o cliente viu.")
    }

    // MARK: - Sanitização do id recebido

    @Test("G12 — id do chamador com quebra de linha é recusado (log injection)")
    func test_G12_hostile_correlation_id_is_rejected() {
        #expect(RequestContextMiddleware.sanitizeCorrelationId("abc\nERROR forjado") == nil)
        #expect(RequestContextMiddleware.sanitizeCorrelationId("abc\r\nfake") == nil)
        #expect(RequestContextMiddleware.sanitizeCorrelationId("id com espaço") == nil)
        #expect(RequestContextMiddleware.sanitizeCorrelationId("") == nil)
        #expect(RequestContextMiddleware.sanitizeCorrelationId(
            String(repeating: "a", count: RequestContextMiddleware.maxCorrelationIdLength + 1)
        ) == nil)
    }

    @Test("G12 — id bem formado do chamador é preservado")
    func test_G12_wellformed_correlation_id_is_kept() {
        let uuid = UUID().uuidString.lowercased()
        #expect(RequestContextMiddleware.sanitizeCorrelationId(uuid) == uuid)
        #expect(RequestContextMiddleware.sanitizeCorrelationId(" bff-01HZX9K3QF ") == "bff-01HZX9K3QF")
    }

    // MARK: - W3C Trace Context

    @Test("G12 — traceparent válido rende o trace-id")
    func test_G12_traceparent_yields_trace_id() {
        let header = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
        #expect(RequestContextMiddleware.traceId(fromTraceparent: header) == "4bf92f3577b34da6a3ce929d0e0e4736")
    }

    @Test("G12 — traceparent inválido não vira correlação")
    func test_G12_invalid_traceparent_is_ignored() {
        // trace-id "tudo zero" é proibido pela própria spec do W3C.
        #expect(RequestContextMiddleware.traceId(fromTraceparent: "00-00000000000000000000000000000000-00f067aa0ba902b7-01") == nil)
        #expect(RequestContextMiddleware.traceId(fromTraceparent: "00-abc-def-01") == nil)
        #expect(RequestContextMiddleware.traceId(fromTraceparent: "lixo") == nil)
        #expect(RequestContextMiddleware.traceId(fromTraceparent: "00-4bf92f3577b34da6a3ce929d0e0e473g-00f067aa0ba902b7-01") == nil)
    }

    @Test("G12 — X-Request-Id tem precedência sobre traceparent")
    func test_G12_explicit_header_wins() {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: RequestContextMiddleware.headerName, value: "explicito-123")
        headers.replaceOrAdd(name: "traceparent", value: "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01")
        #expect(RequestContextMiddleware.correlationId(from: headers) == "explicito-123")
    }

    // MARK: - Rótulo de rota e duração

    @Test("G12 — path de rota não casada é neutralizado antes de virar log")
    func test_G12_unmatched_path_is_sanitized() {
        let injected = RequestContextMiddleware.sanitizePath("/api/v1/\nERROR forjado")
        #expect(!injected.contains("\n"))

        let long = RequestContextMiddleware.sanitizePath("/" + String(repeating: "x", count: 500))
        #expect(long.count <= 121)
    }

    @Test("G12 — duração vem do clock injetado, não do relógio do sistema")
    func test_G12_duration_uses_injected_clock() {
        let clock = TestClock(start: Date(timeIntervalSince1970: 1_000_000))
        let start = clock.instant
        clock.advance(by: 0.25)
        #expect(RequestContextMiddleware.elapsedMilliseconds(from: start, to: clock.instant) == 250)
    }
}
