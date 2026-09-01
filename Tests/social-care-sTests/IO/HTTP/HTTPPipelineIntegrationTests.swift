import Foundation
import Testing
import Vapor
import VaporTesting
@testable import social_care_s

/// Gap **G10** — a cadeia HTTP exercitada ponta a ponta.
///
/// Até aqui nenhum teste subia uma `Application`: os testes de Application
/// chamam os handlers direto, e os de Auth verificam o `OIDCJWTPayload`
/// isolado. O trecho `SecurityHeaders → AppError → JWTAuth → RoleGuard →
/// controller` — que é onde moram a autorização e o formato de erro que o
/// cliente enxerga — nunca tinha sido percorrido. Daí `IO` em 9,1% de
/// cobertura.
///
/// O que estes testes protegem, em ordem de gravidade se quebrar:
/// 1. rota protegida que passe a responder sem token;
/// 2. `RoleGuard` que aceite uma role que não devia (escalada de privilégio);
/// 3. header de segurança que suma justamente na resposta de erro (ADR-012);
/// 4. formato do corpo de erro, que é contrato com o BFF.
@Suite("G10 — pipeline HTTP ponta a ponta")
struct HTTPPipelineIntegrationTests {

    // MARK: - Rotas públicas

    @Test("GET /health responde 200 sem Authorization (rota pública)")
    func healthIsPublic() async throws {
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/health") { res async in
                #expect(res.status == .ok)
            }
        }
    }

    @Test("Rota pública recebe headers de segurança, mas NÃO Cache-Control")
    func publicRouteSecurityHeaders() async throws {
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/health") { res async in
                #expect(res.headers.first(name: "Strict-Transport-Security")
                        == "max-age=63072000; includeSubDomains; preload")
                #expect(res.headers.first(name: "X-Content-Type-Options") == "nosniff")
                #expect(res.headers.first(name: "X-Frame-Options") == "DENY")
                #expect(res.headers.first(name: "Referrer-Policy") == "no-referrer")
                // `/health` é cacheável de propósito — monitoramento.
                #expect(res.headers.first(name: "Cache-Control") == nil)
            }
        }
    }

    @Test("GET /ready responde 200 quando o banco responde")
    func readyWhenDatabaseAnswers() async throws {
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/ready") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("ready"))
            }
        }
    }

    @Test("GET /ready responde 503 quando o banco falha")
    func readyWhenDatabaseFails() async throws {
        try await HTTPTestApp.withApp(databaseFailure: StubDatabaseUnavailable()) { app in
            try await app.testing().test(.GET, "/ready") { res async in
                #expect(res.status == .serviceUnavailable)
                #expect(res.body.string.contains("unavailable"))
            }
        }
    }

    // MARK: - Autenticação (401)

    @Test("Rota protegida sem Authorization responde 401 com corpo genérico")
    func protectedRouteWithoutTokenIs401() async throws {
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .unauthorized)
                // AppSec HIGH-B: 401 não pode virar oracle — mensagem genérica.
                #expect(res.body.string.contains("Unauthorized."))
                #expect(res.body.string.contains("HTTP-401"))
            }
        }
    }

    @Test("Token expirado responde 401")
    func expiredTokenIs401() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: ["worker"], expiresIn: -3600)
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("Token de issuer fora da whitelist responde 401")
    func foreignIssuerIs401() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(
                roles: ["worker"],
                issuer: "https://idp-invasor.example.com"
            )
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("Token com audience de outro serviço responde 401")
    func foreignAudienceIs401() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(
                roles: ["worker"],
                audience: "outro-servico"
            )
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("Token malformado responde 401 (e não 500)")
    func malformedTokenIs401() async throws {
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer("nao.e.um.jwt")
            ) { res async in
                #expect(res.status == .unauthorized)
            }
        }
    }

    // MARK: - Autorização (403) — RoleGuard

    @Test("Token válido sem nenhuma role responde 403")
    func tokenWithoutRolesIs403() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: [])
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .forbidden)
                #expect(res.body.string.contains("Insufficient permissions."))
            }
        }
    }

    @Test("Role 'owner' lê a lista mas NÃO registra paciente (escrita é de 'worker')")
    func ownerCannotWrite() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: ["owner"])
            try await app.testing().test(
                .POST, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .forbidden)
            }
        }
    }

    @Test("Role 'admin' também não registra paciente — escrita é exclusiva de 'worker'")
    func adminCannotWrite() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: ["admin"])
            try await app.testing().test(
                .POST, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .forbidden)
            }
        }
    }

    @Test("Role desconhecida não vira acesso — responde 403")
    func unknownRoleIs403() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: ["social_worker"])
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .forbidden)
            }
        }
    }

    // MARK: - Caminho autorizado: a requisição alcança o controller

    @Test("Role 'worker' atravessa o pipeline e a requisição chega no repositório")
    func workerReachesTheController() async throws {
        try await HTTPTestApp.withApp { app in
            let stub = try #require(app.services.db as? StubSQLDatabase)
            let token = try await HTTPTestApp.token(roles: ["worker"])

            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .ok)
            }

            // A prova de que a requisição não parou num middleware: o
            // controller chamou o handler, que consultou o repositório.
            #expect(!stub.executedSQL.isEmpty)
            #expect(stub.executedSQL.contains { $0.lowercased().contains("select") })
        }
    }

    @Test("Role 'owner' também lê a lista (leitura é worker/owner/admin)")
    func ownerCanRead() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: ["owner"])
            try await app.testing().test(
                .GET, "/api/v1/patients", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .ok)
            }
        }
    }

    // MARK: - Headers na resposta de erro (ADR-012)

    @Test("Resposta 401 TAMBÉM recebe os headers de segurança e Cache-Control")
    func errorResponseKeepsSecurityHeaders() async throws {
        // Esta é a razão de `SecurityHeadersMiddleware` ser registrado primeiro
        // em `configure.swift`: se a ordem inverter, o error path passa a
        // responder sem os headers e nada mais acusa.
        try await HTTPTestApp.withApp { app in
            try await app.testing().test(.GET, "/api/v1/patients") { res async in
                #expect(res.status == .unauthorized)
                #expect(res.headers.first(name: "X-Content-Type-Options") == "nosniff")
                #expect(res.headers.first(name: "X-Frame-Options") == "DENY")
                #expect(res.headers.first(name: "Referrer-Policy") == "no-referrer")
                // Rota /api/* — payload autenticado não pode ser cacheado.
                #expect(res.headers.first(name: "Cache-Control") == "no-store")
            }
        }
    }

    @Test("Rota inexistente responde 404 no formato de erro do middleware")
    func unknownRouteIs404() async throws {
        try await HTTPTestApp.withApp { app in
            let token = try await HTTPTestApp.token(roles: ["worker"])
            try await app.testing().test(
                .GET, "/api/v1/rota-que-nao-existe", headers: .bearer(token)
            ) { res async in
                #expect(res.status == .notFound)
                #expect(res.body.string.contains("HTTP-404"))
            }
        }
    }
}
