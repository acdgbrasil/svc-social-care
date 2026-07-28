import Foundation
import JWT
import Logging
import NIOConcurrencyHelpers
import Vapor

// MARK: - Ports (ADR-040)

/// Porta de fetch de JWKS. Desacopla o `JWKSRefresher` da rede: a implementação
/// de produção usa `app.client` (HTTP); os testes usam um fake determinístico.
protocol JWKSFetching: Sendable {
    /// Busca o documento JWKS (JSON) da `url` informada.
    /// - Parameter url: endpoint JWKS do IdP.
    /// - Returns: corpo JSON do JWKS.
    func fetch(url: String) async throws -> String
}

/// Porta mínima do key store de JWT. Abstrai o `JWTKeyCollection` do JWTKit para
/// que o refresher seja testável com um fake, sem instanciar um key store real.
protocol JWKSKeyStore: Sendable {
    /// Aplica um JWKS (JSON) ao store. Contrato: **upsert por `kid`** — chaves
    /// cujo `kid` não veio no novo JWKS permanecem (não substituir o set inteiro,
    /// senão quebra tokens em voo durante a rotação do IdP).
    func addJWKS(json: String) async throws
}

/// `JWTKeyCollection` (jwt-kit 5.3.0) já é um `actor` e `add(jwksJSON:)` faz
/// upsert por `kid` — exatamente o contrato de `JWKSKeyStore`. Conformamos via
/// extension (o protocolo é nosso, então não há conformance retroativa a marcar).
extension JWTKeyCollection: JWKSKeyStore {
    func addJWKS(json: String) async throws {
        try self.add(jwksJSON: json)
    }
}

// MARK: - HTTP fetcher (produção)

/// Implementação HTTP de `JWKSFetching` sobre o `Client` do Vapor.
struct HTTPJWKSFetcher: JWKSFetching {
    let client: any Client

    func fetch(url: String) async throws -> String {
        let response = try await client.get(URI(string: url))
        guard let body = response.body else {
            throw Abort(.internalServerError, reason: "Empty JWKS response from \(url)")
        }
        let json = String(buffer: body)
        guard json.trimmingCharacters(in: .whitespaces).hasPrefix("{") else {
            throw Abort(.internalServerError, reason: "JWKS response is not JSON from \(url)")
        }
        return json
    }
}

// MARK: - Refresher (ADR-040)

/// Atualiza o key store de JWKS em runtime — **híbrido** (paridade com o
/// `people-context`):
///
/// - **Periódico** (`runPeriodic`): re-fetcha todos os `urls` a cada `interval`
///   e re-aplica via upsert por `kid`. Cancelado no shutdown pelo lifecycle.
/// - **On-demand** (`refreshIfKidUnknown`): chamado pelo `JWTAuthMiddleware` no
///   caminho de erro; só dispara refresh se o `kid` do token é desconhecido
///   **e** já passou o `cooldown` (anti-hammering contra o IdP).
///
/// `knownKids` **espelha** os `kid` já presentes no key store (extraídos
/// decodificando o `JWKS` do JWTKit). Como o `JWTKit` não expõe erro limpo de
/// "kid ausente", o middleware compara o `kid` do token com este espelho.
///
/// Clock injetável (`now`, ADR-034) permite testar o cooldown sem tempo real.
actor JWKSRefresher {
    private let urls: [String]
    private let fetcher: any JWKSFetching
    private let keyStore: any JWKSKeyStore
    private let interval: TimeInterval
    private let cooldown: TimeInterval
    private let now: @Sendable () -> Date
    private let logger: Logger

    /// Espelho dos `kid` conhecidos pelo key store. Cresce monotonicamente (como
    /// o store, que mantém as chaves antigas no upsert).
    private(set) var knownKids: Set<String> = []

    /// Instante da última tentativa de refresh (base do cooldown). Marcado no
    /// **início** de `refresh()` — assim uma tentativa que falha ainda respeita
    /// o cooldown, evitando martelar um IdP indisponível.
    private var lastRefresh: Date?

    init(
        urls: [String],
        fetcher: any JWKSFetching,
        keyStore: any JWKSKeyStore,
        interval: TimeInterval = 600,
        cooldown: TimeInterval = 30,
        now: @escaping @Sendable () -> Date = { Date() },
        logger: Logger = Logger(label: "jwks-refresher")
    ) {
        self.urls = urls
        self.fetcher = fetcher
        self.keyStore = keyStore
        self.interval = interval
        self.cooldown = cooldown
        self.now = now
        self.logger = logger
    }

    /// Semeia `knownKids` a partir dos JWKS já carregados no boot (sem re-fetch).
    /// Espelho inicial do key store — o on-demand não dispara para um `kid` que
    /// o boot já conhece.
    func seedKnownKids(fromJWKS jsons: [String]) {
        for json in jsons {
            knownKids.formUnion(Self.extractKids(from: json))
        }
    }

    /// Re-fetcha todos os `urls`, aplica cada JWKS no key store (upsert por
    /// `kid`) e atualiza `knownKids`. Usado pelo periódico e pelo on-demand.
    func refresh() async throws {
        lastRefresh = now()
        var collected: Set<String> = []
        for url in urls {
            let json = try await fetcher.fetch(url: url)
            try await keyStore.addJWKS(json: json)
            collected.formUnion(Self.extractKids(from: json))
        }
        knownKids.formUnion(collected)
        logger.debug("JWKS refresh concluído", metadata: ["knownKids": .string("\(knownKids.count)")])
    }

    /// Dispara `refresh()` **apenas** se `kid` é desconhecido e o cooldown já
    /// passou. Anti-hammering: um burst de tokens com `kid` inválido gera no
    /// máximo 1 fetch por janela de cooldown por réplica.
    /// - Returns: `true` se refetchou; `false` se o `kid` já é conhecido, se
    ///   ainda está no cooldown, ou se o refresh falhou.
    @discardableResult
    func refreshIfKidUnknown(_ kid: String) async -> Bool {
        guard !knownKids.contains(kid) else { return false }
        if let last = lastRefresh, now().timeIntervalSince(last) < cooldown {
            return false
        }
        do {
            try await refresh()
            return true
        } catch {
            logger.warning("JWKS on-demand refresh falhou", metadata: LogSanitizer.metadata(for: error))
            return false
        }
    }

    /// Loop periódico: dorme `interval`, então refresha. Termina no cancelamento
    /// (shutdown). Dorme antes do primeiro refresh porque o boot já carregou o
    /// JWKS inicial.
    func runPeriodic() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { break }
            do {
                try await refresh()
            } catch {
                logger.warning("JWKS refresh periódico falhou", metadata: LogSanitizer.metadata(for: error))
            }
        }
    }

    /// Extrai os `kid` de um documento JWKS decodificando `JWKS` do JWTKit
    /// (não parsing manual). Retorna vazio se o JSON não for um JWKS válido.
    static func extractKids(from json: String) -> Set<String> {
        guard let jwks = try? JSONDecoder().decode(JWKS.self, from: Data(json.utf8)) else {
            return []
        }
        return Set(jwks.keys.compactMap { $0.keyIdentifier?.string })
    }
}

// MARK: - Application storage

private struct JWKSRefresherKey: StorageKey {
    typealias Value = JWKSRefresher
}

extension Application {
    /// Refresher de JWKS em runtime (ADR-040). Acessado pelo `JWTAuthMiddleware`
    /// para o refresh on-demand por `kid`. `nil` se não configurado (ex.: testes
    /// que não montam o boot) → middleware apenas não faz o retry.
    var jwksRefresher: JWKSRefresher? {
        get { storage[JWKSRefresherKey.self] }
        set { storage[JWKSRefresherKey.self] = newValue }
    }
}

// MARK: - Lifecycle scheduler

/// Agenda o refresh periódico de JWKS (ADR-040) no ciclo de vida da app e o
/// cancela no shutdown. Integra o background task ao lifecycle do Vapor
/// (mesmo padrão do `GracefulShutdownHandler`).
///
/// `@unchecked Sendable`: a `Task` é guardada num `NIOLockedValueBox`
/// (thread-safe); os demais campos são `Sendable`.
final class JWKSRefreshScheduler: LifecycleHandler, @unchecked Sendable {
    private let refresher: JWKSRefresher
    private let logger: Logger
    private let task = NIOLockedValueBox<Task<Void, Never>?>(nil)

    init(refresher: JWKSRefresher, logger: Logger) {
        self.refresher = refresher
        self.logger = logger
    }

    func didBoot(_ application: Application) throws {
        let started = Task { [refresher] in
            await refresher.runPeriodic()
        }
        task.withLockedValue { $0 = started }
        logger.info("JWKS refresher periódico agendado")
    }

    func shutdown(_ application: Application) {
        task.withLockedValue { box in
            box?.cancel()
            box = nil
        }
        logger.info("JWKS refresher periódico cancelado")
    }
}
