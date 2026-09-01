import Foundation
import Testing
import Vapor
@testable import social_care_s

// gap: G13 — CORS
// ADR: ADR-045 — CORS opt-in por allowlist explícita

/// Regressão do **G13 / ADR-045**.
///
/// O default de fábrica do Vapor (`CORSMiddleware.Configuration.default()`) usa
/// `allowedOrigin: .originBased` — **ecoa a origem que a requisição mandou**, o
/// que na prática libera qualquer site a chamar a API com o token do usuário.
/// É o caminho de menor esforço, e é o que esta suite impede.
@Suite("Regression: Security — G13 CORS por allowlist")
struct CORSPolicyRegressionTests {

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

    // MARK: - Opt-in

    @Test("G13 — sem CORS_ALLOWED_ORIGINS não há configuração (middleware não entra na cadeia)")
    func test_G13_cors_is_opt_in() throws {
        #expect(try CORSPolicy.configuration(originsCSV: nil, isProduction: true) == nil)
        #expect(try CORSPolicy.configuration(originsCSV: "", isProduction: true) == nil)
        #expect(try CORSPolicy.configuration(originsCSV: "  ,  ", isProduction: true) == nil)
    }

    // MARK: - Allowlist, nunca eco

    @Test("G13 — a origem permitida é sempre uma lista, nunca o eco do request")
    func test_G13_never_origin_based() throws {
        let configuration = try #require(
            try CORSPolicy.configuration(
                originsCSV: "https://app.acdgbrasil.com.br,https://admin.acdgbrasil.com.br",
                isProduction: true
            )
        )
        let setting = String(describing: configuration.allowedOrigin)
        #expect(setting.hasPrefix("any("),
                "G13: allowedOrigin virou \(setting). `.originBased` ecoa qualquer origem — a API fica aberta a qualquer site que tenha um token.")
        #expect(setting.contains("https://app.acdgbrasil.com.br"))
        #expect(setting.contains("https://admin.acdgbrasil.com.br"))
    }

    @Test("G13 — configure.swift não usa o default de fábrica do Vapor")
    func test_G13_configure_does_not_use_vapor_default() {
        let configure = source("Sources/social-care-s/IO/HTTP/Bootstrap/configure.swift")
        #expect(!configure.contains("CORSMiddleware.Configuration.default()"),
                "G13: configure.swift usa o default do Vapor, que é `.originBased` — use CORSPolicy.")
        #expect(configure.contains("CORSPolicy.configuration"),
                "G13: configure.swift não passa mais pela CORSPolicy — a allowlist deixou de ser aplicada.")
    }

    @Test("G13 — CORS é registrado ANTES do AppErrorMiddleware")
    func test_G13_cors_runs_before_error_middleware() {
        // Resposta de erro sem header de CORS chega no navegador como falha de
        // rede opaca: o front-end vê "network error" em vez do 403 real.
        let configure = source("Sources/social-care-s/IO/HTTP/Bootstrap/configure.swift")
        guard let cors = configure.range(of: "CORSMiddleware(configuration:"),
              let appError = configure.range(of: "app.middleware.use(AppErrorMiddleware())") else {
            Issue.record("G13: não foi possível localizar os middlewares em configure.swift")
            return
        }
        #expect(cors.lowerBound < appError.lowerBound,
                "G13: CORSMiddleware DEVE ser registrado antes do AppErrorMiddleware.")
    }

    // MARK: - Wildcard

    @Test("G13 — '*' é recusado em produção (fail-fast no boot)")
    func test_G13_wildcard_rejected_in_production() {
        #expect(throws: (any Error).self) {
            _ = try CORSPolicy.configuration(originsCSV: "*", isProduction: true)
        }
        #expect(throws: (any Error).self) {
            _ = try CORSPolicy.configuration(originsCSV: "https://app.acdgbrasil.com.br,*", isProduction: true)
        }
    }

    @Test("G13 — '*' é aceito fora de produção (dev com front-end local)")
    func test_G13_wildcard_allowed_outside_production() throws {
        let configuration = try #require(
            try CORSPolicy.configuration(originsCSV: "*", isProduction: false)
        )
        #expect(String(describing: configuration.allowedOrigin) == "all")
    }

    // MARK: - Credenciais

    @Test("G13 — allowCredentials é sempre falso: a autenticação é Bearer, não cookie")
    func test_G13_never_allows_credentials() throws {
        let configuration = try #require(
            try CORSPolicy.configuration(originsCSV: "https://app.acdgbrasil.com.br", isProduction: true)
        )
        #expect(configuration.allowCredentials == false,
                "G13: com credentials ligado o navegador anexaria cookie a requisição cross-origin — CSRF sem contrapartida, já que o serviço autentica por Bearer (ADR-023).")
    }

    // MARK: - Normalização

    @Test("G13 — origem com barra final e espaços é normalizada")
    func test_G13_origins_are_normalized() {
        // O header `Origin` do navegador nunca traz barra final: allowlist com
        // barra nunca casaria, e o sintoma seria "CORS não funciona" sem erro.
        let origins = CORSPolicy.parseOrigins(" https://app.acdgbrasil.com.br/ , https://admin.acdgbrasil.com.br ")
        #expect(origins == ["https://app.acdgbrasil.com.br", "https://admin.acdgbrasil.com.br"])
    }
}
