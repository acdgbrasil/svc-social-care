import Foundation
@testable import social_care_s

/// Fixture centralizada para testes de regressão (`Tests/.../Regression/`).
///
/// Centraliza helpers determinísticos para que testes de regressão sejam
/// reproduzíveis bit-a-bit em CI. Foi introduzida pelo ticket T-001 da
/// o pipeline de remediacao de 2026-05-14 (historico no git) e é coberta pela
/// política ADR-002.
///
/// Princípio: testes de regressão não podem ser flaky. Toda dependência de
/// tempo, identidade ou estado externo passa por aqui — nunca pelo `.now`
/// global ou `UUID()` direto.
enum RegressionFixture {

    // MARK: - Determinístico: clock

    /// Retorna uma closure que sempre devolve o mesmo `TimeStamp`, simulando
    /// um relógio congelado para o teste.
    ///
    /// Uso típico em handlers que precisam de `clock: () -> TimeStamp`:
    ///
    /// ```swift
    /// let clock = RegressionFixture.frozenClock(at: "2026-05-14T12:00:00Z")
    /// let handler = RegisterPatientCommandHandler(clock: clock, ...)
    /// ```
    ///
    /// - Parameter iso: Instante a congelar em formato ISO8601. Default é
    ///   `2026-05-14T12:00:00Z` (data de criação desta fixture).
    static func frozenClock(at iso: String = "2026-05-14T12:00:00Z") -> @Sendable () -> TimeStamp {
        guard let frozen = try? TimeStamp(iso: iso) else {
            preconditionFailure("RegressionFixture.frozenClock recebeu ISO inválido: \(iso)")
        }
        return { frozen }
    }

    /// Retorna um `TimeStamp` determinístico — versão eager para testes que
    /// precisam do valor direto, não da closure.
    static func frozenTimestamp(at iso: String = "2026-05-14T12:00:00Z") -> TimeStamp {
        guard let frozen = try? TimeStamp(iso: iso) else {
            preconditionFailure("RegressionFixture.frozenTimestamp recebeu ISO inválido: \(iso)")
        }
        return frozen
    }

    // MARK: - Lookups pre-populados

    /// Retorna um `InMemoryLookupValidator` já com os IDs informados
    /// registrados nas tabelas correspondentes — evita boilerplate de
    /// `await validator.register(...)` em cada teste.
    ///
    /// - Parameter entries: Mapa `tabela → [LookupId]` a registrar.
    static func prepopulatedLookupValidator(
        _ entries: [String: [LookupId]] = [:]
    ) async -> InMemoryLookupValidator {
        let validator = InMemoryLookupValidator()
        for (table, ids) in entries {
            await validator.registerAll(ids: ids, in: table)
        }
        return validator
    }

    /// Atalho: validator que aceita qualquer ID em qualquer tabela. Usar
    /// somente quando o teste **não** está exercitando validação de lookup
    /// — caso contrário, prepopular com `prepopulatedLookupValidator`.
    static func permissiveLookupValidator() -> AllowAllLookupValidator {
        AllowAllLookupValidator()
    }

    // O `StubUnitOfWork` que vivia aqui foi removido em 2026-09-01. Era
    // placeholder do ticket T-030 do pipeline de remediação, que nunca virou
    // decisão — o ADR reservado àquele ID jamais foi escrito, e a atomicidade
    // que ele prometia resolver já é atendida pelo repositório, que grava
    // agregado e eventos na mesma transação (ADR-014). O stub não testava
    // atomicidade (executava o bloco direto) e seus dois únicos testes
    // exercitavam o próprio stub. A proposta de Unit of Work cross-repository,
    // se voltar, está em `docs/adr/BACKLOG.md` (#14).

    // MARK: - UUID determinístico

    /// Gera um UUID determinístico a partir de uma seed numérica. Útil para
    /// testes que precisam de IDs estáveis sem depender de fixtures
    /// hardcoded em string.
    ///
    /// ```swift
    /// let patientId = RegressionFixture.uuid(seed: 1)
    /// // → 00000000-0000-0000-0000-000000000001
    /// ```
    static func uuid(seed: UInt64) -> UUID {
        let bytes: [UInt8] = [
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            UInt8((seed >> 24) & 0xFF),
            UInt8((seed >> 16) & 0xFF),
            UInt8((seed >> 8)  & 0xFF),
            UInt8(seed         & 0xFF),
        ]
        return UUID(uuid: (
            bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
