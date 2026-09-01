import Foundation
import Vapor

// MARK: - Configuração

/// Parâmetros do rate limit (gap **G14**, ADR-046).
struct RateLimitConfiguration: Sendable {
    /// Requisições permitidas por janela, por chave.
    let limit: Int
    /// Tamanho da janela, em segundos.
    let window: TimeInterval
    /// Se `true`, a chave sai de `X-Forwarded-For` / `X-Real-IP`.
    ///
    /// **Só ligue com um proxy que reescreve esses headers.** Se qualquer
    /// cliente puder falar direto com o serviço, confiar no header é entregar o
    /// bypass: basta mandar um `X-Forwarded-For` diferente a cada requisição.
    let trustProxy: Bool

    static let defaultLimit = 300
    static let defaultWindow: TimeInterval = 60

    init(limit: Int = RateLimitConfiguration.defaultLimit,
         window: TimeInterval = RateLimitConfiguration.defaultWindow,
         trustProxy: Bool = false) {
        self.limit = max(1, limit)
        self.window = max(1, window)
        self.trustProxy = trustProxy
    }

    /// Lê `RATE_LIMIT_ENABLED`, `RATE_LIMIT_REQUESTS`, `RATE_LIMIT_WINDOW_SECONDS`
    /// e `TRUST_PROXY`. Devolve `nil` quando desligado explicitamente.
    ///
    /// Ligado por default: um serviço público sem teto de requisição é DoS de
    /// custo zero para quem ataca. O default (300/min) é folgado de propósito —
    /// ver a nota sobre proxy no ADR-046.
    static func fromEnvironment(_ get: (String) -> String? = { Environment.get($0) }) -> RateLimitConfiguration? {
        if let enabled = get("RATE_LIMIT_ENABLED")?.lowercased(),
           ["false", "0", "no", "off"].contains(enabled) {
            return nil
        }
        return RateLimitConfiguration(
            limit: get("RATE_LIMIT_REQUESTS").flatMap(Int.init) ?? defaultLimit,
            window: get("RATE_LIMIT_WINDOW_SECONDS").flatMap(Double.init) ?? defaultWindow,
            trustProxy: get("TRUST_PROXY")?.lowercased() == "true"
        )
    }
}

// MARK: - Limitador

/// Token bucket por chave, em memória do processo (ADR-046).
///
/// **Token bucket, não janela fixa:** a janela fixa deixa passar 2× o limite na
/// virada (o burst do fim de uma janela soma com o do começo da seguinte). O
/// balde repõe crédito continuamente (`limit / window` por segundo) e absorve
/// burst legítimo até a capacidade, sem essa borda.
///
/// **Por réplica.** Não há store compartilhado: com N pods, o teto efetivo é
/// N × `limit`. É a troca deliberada por não introduzir Redis — ver ADR-046.
///
/// Clock injetável (ADR-034): o teste avança o tempo em vez de dormir.
actor RateLimiter {

    /// Decisão sobre uma requisição, já com o que os headers precisam.
    struct Decision: Sendable, Equatable {
        let allowed: Bool
        let limit: Int
        /// Créditos inteiros restantes depois desta requisição.
        let remaining: Int
        /// Segundos até haver crédito de novo. `0` quando a requisição passou.
        let retryAfterSeconds: Int
        /// Instante em que o balde volta a estar cheio.
        let resetAt: Date
    }

    private struct Bucket {
        var tokens: Double
        var updatedAt: Date
    }

    /// Teto default de chaves rastreadas. Cada chave é um IP; sem teto, um scan
    /// de origens forjadas viraria consumo de memória ilimitado.
    static let defaultMaxTrackedKeys = 10_000

    private let capacity: Double
    private let refillPerSecond: Double
    private let limit: Int
    private let maxTrackedKeys: Int
    private let now: @Sendable () -> Date
    private var buckets: [String: Bucket] = [:]

    init(
        configuration: RateLimitConfiguration,
        now: @escaping @Sendable () -> Date = { Date() },
        maxTrackedKeys: Int = RateLimiter.defaultMaxTrackedKeys
    ) {
        self.limit = configuration.limit
        self.capacity = Double(configuration.limit)
        self.refillPerSecond = Double(configuration.limit) / configuration.window
        self.maxTrackedKeys = max(1, maxTrackedKeys)
        self.now = now
    }

    /// Consome um crédito da chave e devolve a decisão.
    func consume(key: String) -> Decision {
        let instant = now()
        var bucket = buckets[key] ?? Bucket(tokens: capacity, updatedAt: instant)

        let elapsed = max(0, instant.timeIntervalSince(bucket.updatedAt))
        bucket.tokens = min(capacity, bucket.tokens + elapsed * refillPerSecond)
        bucket.updatedAt = instant

        let allowed = bucket.tokens >= 1
        if allowed {
            bucket.tokens -= 1
        }
        buckets[key] = bucket
        evictIfNeeded(at: instant)

        let deficit = allowed ? 0 : (1 - bucket.tokens)
        let secondsToFull = (capacity - bucket.tokens) / refillPerSecond

        return Decision(
            allowed: allowed,
            limit: limit,
            remaining: Int(bucket.tokens.rounded(.down)),
            retryAfterSeconds: allowed ? 0 : max(1, Int((deficit / refillPerSecond).rounded(.up))),
            resetAt: instant.addingTimeInterval(secondsToFull)
        )
    }

    /// Quantidade de chaves vivas — usada pelo teste de eviction.
    var trackedKeys: Int { buckets.count }

    /// Descarta chaves ociosas quando o dicionário passa do teto.
    ///
    /// Balde cheio significa "não deve nada": esquecer essa chave não muda
    /// decisão nenhuma, só devolve memória. Se ainda assim sobrar gente demais,
    /// caem as menos recentes — nunca as que estão perto de estourar o limite.
    private func evictIfNeeded(at instant: Date) {
        guard buckets.count > maxTrackedKeys else { return }

        for (key, bucket) in buckets {
            let refilled = min(capacity, bucket.tokens + max(0, instant.timeIntervalSince(bucket.updatedAt)) * refillPerSecond)
            if refilled >= capacity {
                buckets.removeValue(forKey: key)
            }
        }
        guard buckets.count > maxTrackedKeys else { return }

        let excess = buckets.count - maxTrackedKeys
        let oldest = buckets.sorted { $0.value.updatedAt < $1.value.updatedAt }.prefix(excess)
        for (key, _) in oldest {
            buckets.removeValue(forKey: key)
        }
    }
}

// MARK: - Middleware

/// Aplica o rate limit por cliente antes da autenticação (gap **G14**, ADR-046).
///
/// **Posição na cadeia:** entre o CORS e o `AppErrorMiddleware`, e portanto
/// **antes** do `JWTAuthMiddleware` — é justamente o tráfego não autenticado que
/// precisa de teto. Um limitador depois do auth nunca veria a tentativa de força
/// bruta de token: ela morre no 401.
///
/// Estar por fora do `AppErrorMiddleware` tem uma consequência boa: aqui a
/// resposta já vem pronta, inclusive a de erro, e a cota é anexada a **toda**
/// resposta — quem está queimando crédito em 401 repetido enxerga isso. Em
/// troca, o 429 é montado aqui mesmo, pelo envelope compartilhado
/// (`AppErrorMiddleware.errorResponse`), e não por tradução de `Abort`.
///
/// **Chave é o IP.** O `sub` do JWT seria a chave ideal, mas só existe depois da
/// validação — e chave tirada de token não validado é forjável, o que anula o
/// limite. Ver ADR-046 para o efeito disso atrás de proxy.
struct RateLimitMiddleware: AsyncMiddleware {

    static let limitHeader = "X-RateLimit-Limit"
    static let remainingHeader = "X-RateLimit-Remaining"
    static let resetHeader = "X-RateLimit-Reset"

    /// Probes do orquestrador ficam de fora: o kubelet bate em intervalo fixo e
    /// seria o primeiro a levar 429 — derrubando o pod que estava saudável.
    /// A lista coincide com as rotas públicas do `JWTAuthMiddleware`, mas o
    /// critério é outro (quem chama é a infra, não um cliente).
    static let exemptPaths: Set<String> = ["/health", "/ready"]

    private let limiter: RateLimiter
    private let trustProxy: Bool

    init(limiter: RateLimiter, trustProxy: Bool) {
        self.limiter = limiter
        self.trustProxy = trustProxy
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard !Self.exemptPaths.contains(request.url.path) else {
            return try await next.respond(to: request)
        }

        let key = Self.clientKey(for: request, trustProxy: trustProxy)
        let decision = await limiter.consume(key: key)

        guard decision.allowed else {
            // IP é dado pessoal (LGPD) e o log de acesso não é o lugar dele:
            // registra-se a faixa, que basta para reconhecer abuso concentrado.
            request.logger.warning("rate_limit_exceeded", metadata: [
                "client_range": .string(Self.maskAddress(key)),
                "retry_after_s": .string("\(decision.retryAfterSeconds)")
            ])
            return AppErrorMiddleware.errorResponse(
                status: .tooManyRequests,
                code: "HTTP-429",
                message: "Too many requests.",
                extraHeaders: Self.headers(for: decision, includeRetryAfter: true)
            )
        }

        let response = try await next.respond(to: request)
        for (name, value) in Self.headers(for: decision, includeRetryAfter: false) {
            response.headers.replaceOrAdd(name: name, value: value)
        }
        return response
    }

    // MARK: - Headers

    /// Cota corrente. `X-RateLimit-Reset` é epoch em segundos (formato de fato
    /// dos provedores) e marca quando o balde volta a estar cheio.
    static func headers(for decision: RateLimiter.Decision, includeRetryAfter: Bool) -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: limitHeader, value: "\(decision.limit)")
        headers.replaceOrAdd(name: remainingHeader, value: "\(max(0, decision.remaining))")
        headers.replaceOrAdd(name: resetHeader, value: "\(Int(decision.resetAt.timeIntervalSince1970.rounded()))")
        if includeRetryAfter {
            headers.replaceOrAdd(name: .retryAfter, value: "\(decision.retryAfterSeconds)")
        }
        return headers
    }

    // MARK: - Identificação do cliente

    static func clientKey(for request: Request, trustProxy: Bool) -> String {
        clientKey(
            headers: request.headers,
            remoteAddress: request.remoteAddress?.ipAddress,
            trustProxy: trustProxy
        )
    }

    /// Chave do balde: o IP do cliente.
    ///
    /// Com `trustProxy`, o primeiro IP de `X-Forwarded-For` (o cliente; os
    /// seguintes são os proxies) ou o `X-Real-IP`. O valor é validado como
    /// endereço antes de virar chave — header é entrada de fora, e uma string
    /// arbitrária vira entrada nova no dicionário do limitador.
    ///
    /// Exposto sobre `HTTPHeaders` (e não sobre `Request`) pelo mesmo motivo que
    /// `SecurityHeadersMiddleware.apply(headers:requestPath:)`: dá teste
    /// unitário direto, sem subir uma `Application`.
    static func clientKey(headers: HTTPHeaders, remoteAddress: String?, trustProxy: Bool) -> String {
        let socketAddress = remoteAddress ?? "unknown"
        guard trustProxy else { return socketAddress }

        if let forwarded = headers.first(name: .xForwardedFor),
           let first = forwarded.split(separator: ",").first,
           let candidate = validAddress(String(first)) {
            return candidate
        }
        if let real = headers.first(name: "X-Real-IP"),
           let candidate = validAddress(real) {
            return candidate
        }
        return socketAddress
    }

    /// Aceita só o que parece endereço IP (v4 ou v6), com teto de tamanho.
    static func validAddress(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count <= 45 else { return nil }
        let allowed = Set("0123456789abcdefABCDEF.:")
        guard trimmed.allSatisfy({ allowed.contains($0) }) else { return nil }
        return trimmed
    }

    /// Anonimiza o endereço para log: zera o último octeto do IPv4, mantém o
    /// prefixo /48 do IPv6. Identifica a faixa do abuso sem guardar o cliente.
    static func maskAddress(_ address: String) -> String {
        if address.contains(":") {
            let groups = address.split(separator: ":", omittingEmptySubsequences: false)
            guard groups.count >= 3 else { return "unknown" }
            return groups.prefix(3).joined(separator: ":") + "::/48"
        }
        let octets = address.split(separator: ".")
        guard octets.count == 4 else { return "unknown" }
        return octets.prefix(3).joined(separator: ".") + ".0/24"
    }
}
