import Foundation

/// Entidade que representa um atendimento clínico ou social realizado com o paciente.
///
/// Consolida o histórico de interações entre profissionais e cidadãos, servindo como
/// base para o acompanhamento evolutivo do plano de ação social.
public struct SocialCareAppointment: Codable, Equatable, Sendable {
    
    // MARK: - Constants
    
    private static let summaryLimit = 500
    private static let actionPlanLimit = 2000

    // MARK: - Properties
    
    /// Identificador único do atendimento.
    public let id: AppointmentId
    
    /// Data e hora em que o atendimento ocorreu.
    public let date: TimeStamp
    
    /// Identificador do profissional responsável pelo atendimento.
    public let professionalInChargeId: ProfessionalId
    
    /// A modalidade do atendimento realizado.
    public let type: AppointmentType
    
    /// Resumo técnico das observações e fatos relatados.
    public let summary: String
    
    /// Definições e encaminhamentos para o futuro do paciente.
    public let actionPlan: String

    // MARK: - Nested Types
    
    /// Define as formas de interação possíveis no atendimento.
    public enum AppointmentType: String, Codable, Sendable, CaseIterable {
        case homeVisit = "HOME_VISIT"
        case officeAppointment = "OFFICE_APPOINTMENT"
        case phoneCall = "PHONE_CALL"
        case multidisciplinary = "MULTIDISCIPLINARY"
        case other = "OTHER"
    }

    // MARK: - Initializer

    /// Inicializa uma instância validada de atendimento.
    ///
    /// - Note: Exige que ao menos um dos campos narrativos (summary ou actionPlan) esteja preenchido.
    /// - Throws: `SocialCareAppointmentError` se limites forem excedidos ou datas forem futuras.
    public init(
        id: AppointmentId,
        date: TimeStamp,
        professionalInChargeId: ProfessionalId,
        type: AppointmentType,
        summary: String,
        actionPlan: String,
        now: TimeStamp = .now
    ) throws {
        guard date <= now else {
            throw SocialCareAppointmentError.dateInFuture
        }

        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedActionPlan = actionPlan.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSummary.isEmpty || !trimmedActionPlan.isEmpty else {
            throw SocialCareAppointmentError.missingNarrative
        }

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
    
    public static func == (lhs: SocialCareAppointment, rhs: SocialCareAppointment) -> Bool {
        return lhs.id == rhs.id
    }
}
