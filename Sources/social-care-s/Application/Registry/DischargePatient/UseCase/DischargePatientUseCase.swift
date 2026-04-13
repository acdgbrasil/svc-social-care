import Foundation

/// Contrato para o caso de uso de desligamento de paciente.
public protocol DischargePatientUseCase: CommandHandling where C == DischargePatientCommand {}
