import Vapor

/// Política de CORS do serviço (gap **G13**, ADR-045).
///
/// O `CORSMiddleware` é do Vapor; o que falta nele é *política*. O default de
/// fábrica (`.default()`) usa `allowedOrigin: .originBased`, que **ecoa a origem
/// da requisição** — na prática, libera qualquer site. Aqui só existe allowlist
/// explícita, vinda de `CORS_ALLOWED_ORIGINS` (CSV).
///
/// **Opt-in.** Sem a variável, o middleware não é registrado e a resposta sai
/// sem header de CORS — que é o comportamento correto hoje: o consumidor é o
/// BFF (servidor a servidor, sem navegador no meio) e o gateway Caddy encerra o
/// TLS. CORS só passa a fazer sentido quando um front-end chamar o serviço
/// direto do navegador.
///
/// **`allowCredentials` é `false` e não é configurável.** A autenticação é
/// `Authorization: Bearer` (ADR-023/027) — não há cookie de sessão para o
/// navegador anexar. Ligar credentials só ampliaria a superfície de CSRF sem
/// habilitar nada que o serviço use.
enum CORSPolicy {

    /// Origens permitidas, em CSV. Ausente ou vazia ⇒ CORS desligado.
    static let originsEnvKey = "CORS_ALLOWED_ORIGINS"

    /// Headers que o navegador pode **enviar**. `X-Request-Id` está aqui para
    /// que o front-end possa propagar a correlação (ADR-044).
    static let allowedHeaders: [HTTPHeaders.Name] = [
        .accept,
        .authorization,
        .contentType,
        .origin,
        .xRequestedWith,
        .init(RequestContextMiddleware.headerName)
    ]

    /// Headers que o navegador pode **ler** na resposta. Sem `Access-Control-
    /// Expose-Headers` o JS enxerga só os headers seguros do CORS — o
    /// `X-Request-Id` e a cota de rate limit ficariam invisíveis para o cliente.
    static let exposedHeaders: [HTTPHeaders.Name] = [
        .init(RequestContextMiddleware.headerName),
        .init(RateLimitMiddleware.limitHeader),
        .init(RateLimitMiddleware.remainingHeader),
        .init(RateLimitMiddleware.resetHeader),
        .retryAfter
    ]

    /// Monta a configuração a partir do CSV de origens.
    ///
    /// - Parameters:
    ///   - originsCSV: conteúdo de `CORS_ALLOWED_ORIGINS`.
    ///   - isProduction: em produção, `*` é recusado no boot (fail-fast).
    /// - Returns: `nil` quando não há origem configurada — o chamador então não
    ///   registra o middleware.
    /// - Throws: `Abort` quando a configuração é insegura para o ambiente.
    static func configuration(
        originsCSV: String?,
        isProduction: Bool
    ) throws -> CORSMiddleware.Configuration? {
        let origins = parseOrigins(originsCSV)
        guard !origins.isEmpty else { return nil }

        if origins.contains("*") {
            // `*` com Bearer não é o buraco clássico do `*` com cookie, mas
            // ainda entrega a API a qualquer página que tenha conseguido um
            // token. Em produção isso é erro de configuração, não escolha.
            guard !isProduction else {
                throw Abort(
                    .internalServerError,
                    reason: "CORS_ALLOWED_ORIGINS='*' é recusado em produção — liste as origens."
                )
            }
            return CORSMiddleware.Configuration(
                allowedOrigin: .all,
                allowedMethods: allowedMethods,
                allowedHeaders: allowedHeaders,
                allowCredentials: false,
                cacheExpiration: 600,
                exposedHeaders: exposedHeaders
            )
        }

        return CORSMiddleware.Configuration(
            allowedOrigin: .any(origins),
            allowedMethods: allowedMethods,
            allowedHeaders: allowedHeaders,
            allowCredentials: false,
            cacheExpiration: 600,
            exposedHeaders: exposedHeaders
        )
    }

    /// Os verbos que o serviço realmente expõe (`PatientController` e irmãos) +
    /// `OPTIONS` para o preflight. `HEAD` não entra: nenhuma rota o declara.
    static let allowedMethods: [HTTPMethod] = [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS]

    /// CSV → origens, sem espaços e sem barra final (`https://app.org/` e
    /// `https://app.org` são a mesma origem, mas o header `Origin` do navegador
    /// nunca traz a barra — normalizar evita uma allowlist que nunca casa).
    static func parseOrigins(_ csv: String?) -> [String] {
        guard let csv else { return [] }
        return csv
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { $0.hasSuffix("/") ? String($0.dropLast()) : $0 }
            .filter { !$0.isEmpty }
    }
}
