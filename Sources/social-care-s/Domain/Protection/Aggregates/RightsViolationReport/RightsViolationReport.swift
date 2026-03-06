import Foundation

/// Entidade que representa um relato de violação de direitos.
///
/// Consolida informações críticas sobre incidentes de violência ou negligência,
/// servindo como base para intervenções protetivas e monitoramento de persistência.
public struct RightsViolationReport: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Identificador único do relato.
    public let id: ViolationReportId
    
    /// Data em que o relato foi registrado no sistema.
    public let reportDate: TimeStamp
    
    /// Data (opcional) da ocorrência do fato.
    public let incidentDate: TimeStamp?
    
    /// Identificador da pessoa vítima da violação.
    public let victimId: PersonId
    
    /// A tipificação da violação ocorrida.
    public let violationType: ViolationType
    
    /// Descrição detalhada e factual do ocorrido.
    public let descriptionOfFact: String
    
    /// Providências e ações imediatas tomadas após a ciência do fato.
    public private(set) var actionsTaken: String

    // MARK: - Nested Types
    
    /// Catálogo de tipos de violação de direitos previstos no SUAS.
    public enum ViolationType: String, Codable, Sendable, CaseIterable {
        case neglect = "NEGLECT"
        case psychologicalViolence = "PSYCHOLOGICAL_VIOLENCE"
        case physicalViolence = "PHYSICAL_VIOLENCE"
        case sexualAbuse = "SEXUAL_ABUSE"
        case sexualExploitation = "SEXUAL_EXPLOITATION"
        case childLabor = "CHILD_LABOR"
        case financialExploitation = "FINANCIAL_EXPLOITATION"
        case discrimination = "DISCRIMINATION"
        case other = "OTHER"
    }

    // MARK: - Initializer

    /// Cria uma instância validada de um relato de violação.
    ///
    /// - Throws: `RightsViolationReportError` se datas forem futuras ou descrição estiver vazia.
    public init(
        id: ViolationReportId,
        reportDate: TimeStamp,
        incidentDate: TimeStamp?,
        victimId: PersonId,
        violationType: ViolationType,
        descriptionOfFact: String,
        actionsTaken: String,
        now: TimeStamp = .now
    ) throws {
        guard reportDate <= now else {
            throw RightsViolationReportError.reportDateInFuture
        }

        if let incident = incidentDate {
            guard incident <= reportDate else {
                throw RightsViolationReportError.incidentAfterReport
            }
        }

        let trimmedDescription = descriptionOfFact.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            throw RightsViolationReportError.emptyDescription
        }

        self.id = id
        self.reportDate = reportDate
        self.incidentDate = incidentDate
        self.victimId = victimId
        self.violationType = violationType
        self.descriptionOfFact = trimmedDescription
        self.actionsTaken = actionsTaken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Mutators (Functional)

    /// Atualiza o registro das providências tomadas.
    ///
    /// - Parameter newActions: O novo texto descritivo das ações.
    public mutating func updateActions(_ newActions: String) {
        self.actionsTaken = newActions.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Equatable
    
    public static func == (lhs: RightsViolationReport, rhs: RightsViolationReport) -> Bool {
        return lhs.id == rhs.id
    }
}
