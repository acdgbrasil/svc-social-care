import Foundation

/// Entidade que representa um encaminhamento (Referral) realizado para um serviço externo.
///
/// Gerencia o ciclo de vida de um encaminhamento, garantindo que as transições de status
/// (ex: de pendente para concluído) ocorram de forma consistente e irrevogável.
public struct Referral: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Identificador único do encaminhamento.
    public let id: ReferralId
    
    /// Data em que o encaminhamento foi formalizado.
    public let date: TimeStamp
    
    /// Identificador do profissional que realizou a solicitação.
    public let requestingProfessionalId: ProfessionalId
    
    /// Identificador da pessoa que está sendo encaminhada.
    public let referredPersonId: PersonId
    
    /// O serviço ou unidade de destino.
    public let destinationService: DestinationService
    
    /// A justificativa técnica para o encaminhamento.
    public let reason: String
    
    /// O status atual no ciclo de vida do encaminhamento.
    public private(set) var status: Status

    // MARK: - Nested Types
    
    /// Define os estados possíveis de um encaminhamento.
    public enum Status: String, Codable, Sendable {
        /// Aguardando processamento ou vaga.
        case pending = "PENDING"
        /// Efetivado com sucesso no destino.
        case completed = "COMPLETED"
        /// Cancelado por perda de objeto ou erro.
        case cancelled = "CANCELLED"
    }

    /// Catálogo de serviços de destino previstos na rede de proteção.
    public enum DestinationService: String, Codable, Sendable, CaseIterable {
        case cras = "CRAS"
        case creas = "CREAS"
        case healthCare = "HEALTH_CARE"
        case education = "EDUCATION"
        case legal = "LEGAL"
        case other = "OTHER"
    }

    // MARK: - Initializer

    /// Cria uma instância validada de um encaminhamento.
    ///
    /// - Throws: `ReferralError.dateInFuture` ou `ReferralError.reasonMissing`.
    public init(
        id: ReferralId,
        date: TimeStamp,
        requestingProfessionalId: ProfessionalId,
        referredPersonId: PersonId,
        destinationService: DestinationService,
        reason: String,
        status: Status = .pending,
        now: TimeStamp = .now
    ) throws {
        guard date <= now else {
            throw ReferralError.dateInFuture
        }

        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else {
            throw ReferralError.reasonMissing
        }

        self.id = id
        self.date = date
        self.requestingProfessionalId = requestingProfessionalId
        self.referredPersonId = referredPersonId
        self.destinationService = destinationService
        self.reason = trimmedReason
        self.status = status
    }

    // MARK: - Status Transitions (Functional Mutation)

    /// Marca o encaminhamento como concluído.
    ///
    /// - Note: A transição só é permitida a partir do estado `pending`.
    /// - Throws: `ReferralError.invalidStatusTransition` se o estado atual for inválido.
    public mutating func complete() throws {
        try transition(to: .completed)
    }

    /// Cancela o encaminhamento.
    ///
    /// - Note: A transição só é permitida a partir do estado `pending`.
    /// - Throws: `ReferralError.invalidStatusTransition` se o estado atual for inválido.
    public mutating func cancel() throws {
        try transition(to: .cancelled)
    }

    private mutating func transition(to next: Status) throws {
        guard self.status == .pending else {
            throw ReferralError.invalidStatusTransition(from: self.status.rawValue, to: next.rawValue)
        }
        self.status = next
    }

    // MARK: - Equatable
    
    /// Entidades são iguais se possuem o mesmo identificador.
    public static func == (lhs: Referral, rhs: Referral) -> Bool {
        return lhs.id == rhs.id
    }
}
