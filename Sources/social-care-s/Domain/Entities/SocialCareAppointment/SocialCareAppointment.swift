import Foundation

/// Representa um atendimento clínico de assistência social associado ao paciente.
///
/// Esta é uma Entidade de domínio, identificada unicamente pelo seu `id`.
public struct SocialCareAppointment: Codable, Equatable, Sendable {
    
    // MARK: - Constants
    private static let summaryLimit = 500
    private static let actionPlanLimit = 2000

    // MARK: - Properties
    
    /// Identificador único da entidade.
    public let id: AppointmentId
    
    /// Data em que o atendimento foi realizado.
    public let date: TimeStamp
    
    /// Identificador do profissional responsável pelo atendimento.
    public let professionalInChargeId: ProfessionalId
    
    /// Tipo de atendimento realizado.
    public let type: AppointmentType
    
    /// Resumo textual das observações feitas durante o atendimento.
    public let summary: String
    
    /// Plano de ação definido para o paciente.
    public let actionPlan: String

    // MARK: - Nested Types
    
    public enum AppointmentType: String, Codable, Sendable, CaseIterable {
        case homeVisit = "HOME_VISIT"
        case officeAppointment = "OFFICE_APPOINTMENT"
        case phoneCall = "PHONE_CALL"
        case multidisciplinary = "MULTIDISCIPLINARY"
        case other = "OTHER"
    }

    // MARK: - Initializer

    /// Inicializa uma instância validada de `SocialCareAppointment`.
    ///
    /// - Throws: `SocialCareAppointmentError` em caso de erro de validação.
    public init(
        id: AppointmentId,
        date: TimeStamp,
        professionalInChargeId: ProfessionalId,
        type: AppointmentType,
        summary: String,
        actionPlan: String,
        now: TimeStamp
    ) throws {
        // Validação: Data não pode ser futura
        guard date <= now else {
            throw SocialCareAppointmentError.dateInFuture
        }

        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedActionPlan = actionPlan.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validação: Pelo menos um dos campos narrativos deve estar preenchido
        guard !trimmedSummary.isEmpty || !trimmedActionPlan.isEmpty else {
            throw SocialCareAppointmentError.missingNarrative
        }

        // Validação: Limites de caracteres
        guard trimmedSummary.count <= Self.summaryLimit else {
            throw SocialCareAppointmentError.summaryTooLong(limit: Self.summaryLimit)
        }

        guard trimmedActionPlan.count <= Self.actionPlanLimit else {
            throw SocialCareAppointmentError.actionPlanTooLong(limit: Self.actionPlanLimit)
        }

        self.id = id
        self.date = date
        self.professionalInChargeId = professionalInChargeId
        self.type = type
        self.summary = trimmedSummary
        self.actionPlan = trimmedActionPlan
    }

    // MARK: - Equatable
    
    /// Entidades são iguais se possuem o mesmo identificador único.
    public static func == (lhs: SocialCareAppointment, rhs: SocialCareAppointment) -> Bool {
        return lhs.id == rhs.id
    }
}
