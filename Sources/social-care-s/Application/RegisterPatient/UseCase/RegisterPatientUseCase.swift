import Foundation

/// Contrato para o caso de uso de registro de novo paciente.
protocol RegisterPatientUseCase: Sendable {
    /// Executa o registro de um novo paciente.
    ///
    /// - Parameter command: O payload com os dados iniciais do paciente.
    /// - Returns: O identificador (PatientId) do paciente registrado.
    /// - Throws: `RegisterPatientError` em caso de erro de validação ou persistência.
    func execute(command: RegisterPatientCommand) async throws(RegisterPatientError) -> String
}
