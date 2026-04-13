import Foundation

/// Contrato para o caso de uso de readmissão de paciente.
public protocol ReadmitPatientUseCase: CommandHandling where C == ReadmitPatientCommand {}
