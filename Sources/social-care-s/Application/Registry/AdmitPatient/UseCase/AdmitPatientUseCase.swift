import Foundation

/// Contrato para o caso de uso de admissao de paciente.
public protocol AdmitPatientUseCase: CommandHandling where C == AdmitPatientCommand {}
