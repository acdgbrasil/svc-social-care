import Foundation
import Testing
@testable import social_care_s

// ticket: T-034 — achado S-H-A2 (Senior Code Review)
// ADR: ADR-034 — clock injetável em toda leitura de tempo que decide ou carimba

/// Regressão do achado **S-H-A2**: código que lê o relógio do sistema no meio da
/// própria lógica não é testável deterministicamente. Quem quiser testar "o que
/// acontece depois do cooldown", "o crédito voltou?" ou "o evento foi carimbado
/// com que hora?" só teria duas saídas ruins: dormir (teste lento e flaky) ou
/// não testar.
///
/// A política do ADR-034 tem dois níveis, e cada um é verificado aqui:
///
/// 1. **Domínio** — método que precisa do instante recebe `now:`/`at:` com
///    default `.now`. O default mantém a chamada curta em produção; o parâmetro
///    dá o gancho ao teste. Ler o relógio *dentro* do corpo tira esse gancho.
/// 2. **Componentes que decidem por tempo** — cooldown, janela, duração —
///    recebem a closure `now` no `init`, e o teste injeta o `TestClock`.
///
/// O que fica de fora, deliberadamente: `Date()` usado como **carimbo** em
/// adaptadores de saída (`meta.timestamp` da resposta HTTP, `reviewed_at` do
/// repositório, o `now` do relay do Outbox). Ali o instante não muda decisão
/// nenhuma, e injetar clock em cada adaptador seria cerimônia sem teste do
/// outro lado.
@Suite("Regression: DomainInvariants — S-H-A2 clock injetável")
struct ClockInjectionTest {

    // MARK: - Localização de fontes

    private func projectRoot(file: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: "\(file)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func swiftFiles(in subpath: String) -> [URL] {
        let dir = projectRoot().appendingPathComponent("Sources/social-care-s/\(subpath)")
        guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        var files: [URL] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            files.append(url)
        }
        return files
    }

    // MARK: - Nível 1: o domínio não lê o relógio

    @Test("S-H-A2 — Domain/ só toca o relógio em default de parâmetro")
    func test_S_H_A2_domain_never_reads_the_clock_inline() {
        var offenders: [String] = []

        for file in swiftFiles(in: "Domain") {
            // `TimeStamp.swift` é a definição de `.now` — a única leitura
            // legítima do relógio no domínio, e a que todos os defaults usam.
            guard file.lastPathComponent != "TimeStamp.swift" else { continue }
            let content = (try? String(contentsOf: file, encoding: .utf8)) ?? ""

            for (index, line) in content.components(separatedBy: "\n").enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.contains("Date()") || trimmed.contains(".now") else { continue }
                guard !trimmed.hasPrefix("//"), !trimmed.hasPrefix("///") else { continue }
                // Default de parâmetro: `now: TimeStamp = .now`, `at date: TimeStamp = .now`.
                guard !trimmed.contains("= .now"), !trimmed.contains("= TimeStamp.now") else { continue }
                offenders.append("\(file.lastPathComponent):\(index + 1) — \(trimmed.prefix(80))")
            }
        }

        #expect(offenders.isEmpty,
                "S-H-A2: o domínio lê o relógio fora de default de parâmetro: \(offenders). Receba o instante como `now:`/`at:` — senão o comportamento não é testável sem dormir.")
    }

    @Test("S-H-A2 — agregado carimba com o instante recebido, não com o do sistema")
    func test_S_H_A2_aggregate_stamps_with_injected_instant() throws {
        var patient = try PatientFixture.createMinimalActive()
        let frozen = RegressionFixture.frozenTimestamp(at: "2026-05-14T12:00:00Z")

        try patient.updateHousingCondition(nil, actorId: "actor-1", at: frozen)

        let event = try #require(patient.uncommittedEvents.last)
        #expect(event.occurredAt == frozen.date,
                "S-H-A2: o evento saiu com hora diferente da injetada — o agregado voltou a ler o relógio do sistema.")
    }

    // MARK: - Nível 2: quem decide por tempo recebe o clock

    /// Componentes cuja **decisão** depende do tempo. Entrar aqui é o contrato
    /// do ADR-034: componente novo que decida por tempo entra na lista, e a
    /// lista cobra o `init`.
    private static let timeDrivenComponents: [(path: String, why: String)] = [
        ("IO/HTTP/Auth/JWKSRefresher.swift", "cooldown do refresh on-demand (ADR-040)"),
        ("IO/HTTP/Middleware/RateLimitMiddleware.swift", "janela do token bucket (ADR-046)"),
        ("IO/HTTP/Middleware/RequestContextMiddleware.swift", "duração no log de acesso (ADR-044)")
    ]

    @Test("S-H-A2 — componente que decide por tempo recebe o clock no init")
    func test_S_H_A2_time_driven_components_inject_the_clock() {
        for component in Self.timeDrivenComponents {
            let url = projectRoot().appendingPathComponent("Sources/social-care-s/\(component.path)")
            let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""

            #expect(!content.isEmpty,
                    "S-H-A2: \(component.path) não existe — se foi renomeado, atualize a lista deste teste.")
            #expect(content.contains("@Sendable () -> Date"),
                    "S-H-A2: \(component.path) decide por tempo (\(component.why)) e não recebe clock injetável — o teste desse comportamento passaria a depender de `sleep`.")
        }
    }

    @Test("S-H-A2 — o TestClock é o gancho: avança sem dormir")
    func test_S_H_A2_test_clock_advances_without_sleeping() {
        let clock = TestClock(start: Date(timeIntervalSince1970: 1_000_000))
        let before = clock.reader()
        clock.advance(by: 3600)
        #expect(clock.reader().timeIntervalSince(before) == 3600)
    }
}
