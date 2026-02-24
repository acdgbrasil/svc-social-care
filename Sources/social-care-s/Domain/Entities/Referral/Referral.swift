import Foundation

/// Representa um encaminhamento realizado por um profissional para um serviço específico.
///
/// Esta entidade gerencia o ciclo de vida de um encaminhamento, permitindo transições
/// de status apenas a partir do estado pendente.
public struct Referral: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Identificador único do encaminhamento.
    public let id: ReferralId
    
    /// Data em que o encaminhamento foi solicitado.
    public let date: TimeStamp
    
    /// Identificador do profissional que solicitou o encaminhamento.
    public let requestingProfessionalId: ProfessionalId
    
    /// Identificador da pessoa encaminhada.
    public let referredPersonId: PersonId
    
    /// O serviço de destino para o qual a pessoa foi encaminhada.
    public let destinationService: DestinationService
    
    /// O motivo/justificativa para o encaminhamento.
    public let reason: String
    
    /// O status atual do encaminhamento.
    public let status: Status

    // MARK: - Nested Types
    
    public enum Status: String, Codable, Sendable {
        case pending = "PENDING"
        case completed = "COMPLETED"
        case cancelled = "CANCELLED"
    }

    public enum DestinationService: String, Codable, Sendable, CaseIterable {
        case cras = "CRAS"
        case creas = "CREAS"
        case healthCare = "HEALTH_CARE"
        case education = "EDUCATION"
        case legal = "LEGAL"
        case other = "OTHER"
    }

    // MARK: - Initializer
    
    private init(
        id: ReferralId,
        date: TimeStamp,
        requestingProfessionalId: ProfessionalId,
        referredPersonId: PersonId,
        destinationService: DestinationService,
        reason: String,
        status: Status
    ) {
        self.id = id
        self.date = date
        self.requestingProfessionalId = requestingProfessionalId
        self.referredPersonId = referredPersonId
        self.destinationService = destinationService
        self.reason = reason
        self.status = status
    }

    // MARK: - Factory Method

    /// Cria uma instância validada de `Referral`.
    ///
    /// - Throws: `ReferralError` em caso de erro de validação.
    public static func create(
        id: ReferralId,
        date: TimeStamp,
        requestingProfessionalId: ProfessionalId,
        referredPersonId: PersonId,
        destinationService: DestinationService,
        reason: String,
        status: Status = .pending,
        now: TimeStamp
    ) throws -> Referral {
        
        // Validação: Data não pode ser futura
        guard date <= now else {
            throw ReferralError.dateInFuture
        }

        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validação: Motivo obrigatório
        guard !trimmedReason.isEmpty else {
            throw ReferralError.reasonMissing
        }

        return Referral(
            id: id,
            date: date,
            requestingProfessionalId: requestingProfessionalId,
            referredPersonId: referredPersonId,
            destinationService: destinationService,
            reason: trimmedReason,
            status: status
        )
    }

    // MARK: - Status Transitions (Functional Style)

    /// Finaliza o encaminhamento.
    /// - Throws: `ReferralError.invalidStatusTransition` se não estiver pendente.
    public func complete() throws -> Referral {
        return try transition(to: .completed)
    }

    /// Cancela o encaminhamento.
    /// - Throws: `ReferralError.invalidStatusTransition` se não estiver pendente.
    public func cancel() throws -> Referral {
        return try transition(to: .cancelled)
    }

    private func transition(to next: Status) throws -> Referral {
        guard self.status == .pending else {
            throw ReferralError.invalidStatusTransition(from: self.status.rawValue, to: next.rawValue)
        }
        
        return Referral(
            id: self.id,
            date: self.date,
            requestingProfessionalId: self.requestingProfessionalId,
            referredPersonId: self.referredPersonId,
            destinationService: self.destinationService,
            reason: self.reason,
            status: next
        )
    }

    // MARK: - Equatable
    
    public static func == (lhs: Referral, rhs: Referral) -> Bool {
        return lhs.id == rhs.id
    }
}
