import Foundation

/// Contrato para o caso de uso de criação de encaminhamento.
public protocol CreateReferralUseCase: ResultCommandHandling where C == CreateReferralCommand {}
