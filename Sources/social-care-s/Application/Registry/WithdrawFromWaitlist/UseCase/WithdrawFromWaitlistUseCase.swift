import Foundation

/// Contrato para o caso de uso de retirada de paciente da fila de espera.
public protocol WithdrawFromWaitlistUseCase: CommandHandling where C == WithdrawFromWaitlistCommand {}
