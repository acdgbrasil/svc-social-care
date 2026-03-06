import Foundation

/// Contrato para o caso de uso de registro de novo paciente.
public protocol RegisterPatientUseCase: ResultCommandHandling where C == RegisterPatientCommand {
    /// O método handle herdado de ResultCommandHandling processa o registro.
}
