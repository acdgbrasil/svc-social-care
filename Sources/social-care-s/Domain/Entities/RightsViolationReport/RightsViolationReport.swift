import Foundation

/// Representa um relatório de violação de direitos.
///
/// Esta entidade consolida informações sobre o incidente, a vítima, o tipo de violação
/// e as providências tomadas.
public struct RightsViolationReport: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Identificador único do relatório.
    public let id: ViolationReportId
    
    /// Data em que o relatório foi registrado.
    public let reportDate: TimeStamp
    
    /// Data opcional em que o incidente ocorreu.
    public let incidentDate: TimeStamp?
    
    /// Identificador da pessoa vítima da violação.
    public let victimId: PersonId
    
    /// O tipo de violação ocorrida.
    public let violationType: ViolationType
    
    /// Descrição detalhada dos fatos.
    public let descriptionOfFact: String
    
    /// Providências e ações tomadas após o incidente.
    public let actionsTaken: String

    // MARK: - Nested Types
    
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
    
    private init(
        id: ViolationReportId,
        reportDate: TimeStamp,
        incidentDate: TimeStamp?,
        victimId: PersonId,
        violationType: ViolationType,
        descriptionOfFact: String,
        actionsTaken: String
    ) {
        self.id = id
        self.reportDate = reportDate
        self.incidentDate = incidentDate
        self.victimId = victimId
        self.violationType = violationType
        self.descriptionOfFact = descriptionOfFact
        self.actionsTaken = actionsTaken
    }

    // MARK: - Factory Method

    /// Cria uma instância validada de `RightsViolationReport`.
    ///
    /// - Throws: `RightsViolationReportError` em caso de erro de validação.
    public static func create(
        id: ViolationReportId,
        reportDate: TimeStamp,
        incidentDate: TimeStamp?,
        victimId: PersonId,
        violationType: ViolationType,
        descriptionOfFact: String,
        actionsTaken: String,
        now: TimeStamp
    ) throws -> RightsViolationReport {
        
        // Validação: Data do relatório não pode ser futura
        guard reportDate <= now else {
            throw RightsViolationReportError.reportDateInFuture
        }

        // Validação: Incidente não pode ser após o relatório
        if let incident = incidentDate {
            guard incident <= reportDate else {
                throw RightsViolationReportError.incidentAfterReport
            }
        }

        let trimmedDescription = descriptionOfFact.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validação: Descrição obrigatória
        guard !trimmedDescription.isEmpty else {
            throw RightsViolationReportError.emptyDescription
        }

        return RightsViolationReport(
            id: id,
            reportDate: reportDate,
            incidentDate: incidentDate,
            victimId: victimId,
            violationType: violationType,
            descriptionOfFact: trimmedDescription,
            actionsTaken: actionsTaken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Mutators (Functional Style)

    /// Retorna uma nova instância do relatório com as ações atualizadas.
    ///
    /// - Parameter newActions: O novo texto de providências tomadas.
    /// - Returns: Uma cópia do relatório com o novo estado.
    public func updatingActions(_ newActions: String) -> RightsViolationReport {
        return RightsViolationReport(
            id: self.id,
            reportDate: self.reportDate,
            incidentDate: self.incidentDate,
            victimId: self.victimId,
            violationType: self.violationType,
            descriptionOfFact: self.descriptionOfFact,
            actionsTaken: newActions.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Equatable
    
    /// Entidades são iguais se possuem o mesmo identificador único.
    public static func == (lhs: RightsViolationReport, rhs: RightsViolationReport) -> Bool {
        return lhs.id == rhs.id
    }
}
