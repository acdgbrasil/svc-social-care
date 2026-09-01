import Foundation
import Vapor

/// Correlaciona e registra toda requisição HTTP (gap **G12**, ADR-044).
///
/// Antes deste middleware a observabilidade do serviço era `req.logger` avulso:
/// duas linhas de log da mesma requisição não tinham como ser reunidas, e uma
/// requisição bem-sucedida não deixava rastro nenhum. Aqui a requisição ganha:
///
/// 1. **Identidade** — `correlation_id` no `Logger.Metadata`, herdado por todo
///    log emitido depois (o `AppErrorMiddleware`, o `JWTAuthMiddleware`, os
///    controllers). Como este middleware é mais externo que o `AppError`, o log
///    do caminho de erro também sai correlacionado. O nome distingue do
///    `request-id` que o próprio Vapor gera: aquele é interno e morre no
///    processo; este atravessa serviços e volta no header.
/// 2. **Continuidade** — se o chamador (BFF, gateway) já mandou `X-Request-Id`
///    ou um `traceparent` do W3C Trace Context, esse identificador é reusado, e
///    o mesmo id aparece nos dois serviços. O valor volta na resposta, sempre.
/// 3. **Log de acesso** — uma linha por requisição com método, rota, status e
///    duração.
///
/// ## O que NÃO é logado, e por quê
///
/// - **Query string.** `GET /api/v1/patients?search=` carrega nome e CPF
///   (`PatientController.list`). Log de acesso com query string é vazamento de
///   PII em texto claro no stack de logs — ADR-017 pela via da observabilidade.
/// - **Corpo e headers.** Mesma razão, com agravante de `Authorization`.
/// - **Path bruto de rota casada.** Prefere-se o *template* da rota
///   (`GET /api/v1/patients/:patientId`), que agrega no dashboard e não carrega
///   identificador. Só quando nenhuma rota casa (404) o path entra — sanitizado,
///   porque aí ele é entrada de quem chamou.
///
/// O `actorId` (o `sub` do JWT, mesmo valor que vai para `audit_trail`) entra
/// quando a requisição já passou pela autenticação: sem ele o log de acesso não
/// serve para investigar incidente.
///
/// Clock e gerador de id são injetáveis (ADR-034) — o teste mede duração sem
/// dormir e afirma o id sem sortear.
struct RequestContextMiddleware: AsyncMiddleware {

    /// Header de correlação — lido na entrada, sempre devolvido na saída.
    static let headerName = "X-Request-Id"

    /// Probes do orquestrador. Logadas em `debug` porque o kubelet bate a cada
    /// poucos segundos e afogaria o log de acesso real.
    static let probePaths: Set<String> = ["/health", "/ready"]

    /// Teto do id aceito de fora. Acima disso, geramos o nosso.
    static let maxCorrelationIdLength = 128

    private let generateId: @Sendable () -> String
    private let now: @Sendable () -> Date

    init(
        generateId: @escaping @Sendable () -> String = { UUID().uuidString.lowercased() },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.generateId = generateId
        self.now = now
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let correlationId = Self.correlationId(from: request.headers) ?? generateId()
        request.logger[metadataKey: "correlation_id"] = .string(correlationId)

        let startedAt = now()
        do {
            let response = try await next.respond(to: request)
            response.headers.replaceOrAdd(name: Self.headerName, value: correlationId)
            log(request, status: response.status, startedAt: startedAt)
            return response
        } catch {
            // Rede de segurança: o `AppErrorMiddleware` é mais interno e
            // converte tudo em `Response`. Se algo escapar dele, o log de
            // acesso ainda registra a requisição antes de o erro subir.
            let status = (error as? any AbortError)?.status ?? .internalServerError
            log(request, status: status, startedAt: startedAt)
            throw error
        }
    }

    // MARK: - Log de acesso

    private func log(_ request: Request, status: HTTPResponseStatus, startedAt: Date) {
        let isProbe = Self.probePaths.contains(request.url.path)
        let level: Logger.Level = isProbe ? .debug : (status.code >= 500 ? .error : .info)

        var metadata: Logger.Metadata = [
            "http_method": .string(request.method.rawValue),
            "http_route": .string(Self.routeLabel(for: request)),
            "http_status": .string("\(status.code)"),
            "duration_ms": .string("\(Self.elapsedMilliseconds(from: startedAt, to: now()))")
        ]
        if let actorId = request.authenticatedUser?.userId {
            metadata["actor_id"] = .string(actorId)
        }

        request.logger.log(level: level, "http_request", metadata: metadata)
    }

    /// Duração em milissegundos, arredondada. Inteiro porque log de acesso não
    /// tem uso para a casa decimal e o número entra em dashboard.
    static func elapsedMilliseconds(from start: Date, to end: Date) -> Int {
        max(0, Int((end.timeIntervalSince(start) * 1000).rounded()))
    }

    /// Rótulo da rota: o template quando o router casou (`GET
    /// /api/v1/patients/:patientId`), o path sanitizado quando não casou.
    ///
    /// O template vem do próprio código — é seguro e agrega. O path de um 404 é
    /// entrada de quem chamou: passa pela sanitização antes de virar log.
    static func routeLabel(for request: Request) -> String {
        if let route = request.route {
            return route.description
        }
        return "\(request.method.rawValue) \(sanitizePath(request.url.path))"
    }

    // MARK: - Correlação de entrada

    /// Identificador de correlação vindo do chamador, se houver e se for aceitável.
    ///
    /// Ordem: `X-Request-Id` explícito; senão o `trace-id` de um `traceparent`
    /// do W3C Trace Context (é o que um gateway com OpenTelemetry manda).
    static func correlationId(from headers: HTTPHeaders) -> String? {
        if let raw = headers.first(name: headerName), let sane = sanitizeCorrelationId(raw) {
            return sane
        }
        if let traceparent = headers.first(name: "traceparent"), let traceId = traceId(fromTraceparent: traceparent) {
            return traceId
        }
        return nil
    }

    /// Aceita o id do chamador **só** se ele for inofensivo como conteúdo de log.
    ///
    /// Um `X-Request-Id` é atacante-controlado: sem allowlist, `foo\nERROR fake`
    /// injeta uma linha inteira no log agregado (a mesma classe de problema que
    /// o `LogSanitizer` trata para erros — ADR-017). Aceitamos o alfabeto de
    /// UUID, ULID e trace-id do W3C; qualquer outra coisa vira id novo.
    static func sanitizeCorrelationId(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count <= maxCorrelationIdLength else { return nil }
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.:")
        guard trimmed.allSatisfy({ allowed.contains($0) }) else { return nil }
        return trimmed
    }

    /// Extrai o `trace-id` de um header `traceparent`
    /// (`00-<32 hex trace-id>-<16 hex parent-id>-<2 hex flags>`, W3C Trace
    /// Context). Devolve `nil` se o formato não bate ou se o trace-id é o
    /// inválido "tudo zero" que a própria spec proíbe.
    static func traceId(fromTraceparent header: String) -> String? {
        let fields = header.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count >= 4 else { return nil }
        let traceId = String(fields[1]).lowercased()
        guard traceId.count == 32,
              traceId.allSatisfy({ $0.isHexDigit }),
              traceId.contains(where: { $0 != "0" })
        else {
            return nil
        }
        return traceId
    }

    /// Neutraliza quebras de linha e trunca — mesmo tratamento que o
    /// `LogSanitizer` dá à descrição de erro, pela mesma razão.
    static func sanitizePath(_ path: String) -> String {
        let neutralized = path
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        guard neutralized.count > 120 else { return neutralized }
        return String(neutralized.prefix(120)) + "…"
    }
}
