import Foundation

/// Clock de teste com tempo controlado manualmente (ADR-034).
///
/// É o par de teste do clock injetável: quem depende de tempo para **decidir**
/// — o cooldown do `JWKSRefresher` (ADR-040), a janela do `RateLimiter`
/// (ADR-046), a duração no log de acesso (ADR-044) — recebe `now:` no init e
/// aqui o teste avança o relógio na mão, sem `sleep`. Teste que dorme é teste
/// lento e flaky; o suite de regressão tem alvo de 5s (ADR-002).
///
/// `@unchecked Sendable`: o estado é protegido por `NSLock`.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(start: Date = Date(timeIntervalSince1970: 1_000_000)) {
        self.current = start
    }

    /// Closure `@Sendable` para injetar como `now`.
    var reader: @Sendable () -> Date {
        { [self] in
            lock.lock()
            defer { lock.unlock() }
            return current
        }
    }

    /// Instante corrente, para o teste montar expectativas.
    var instant: Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    func advance(by seconds: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }
}
