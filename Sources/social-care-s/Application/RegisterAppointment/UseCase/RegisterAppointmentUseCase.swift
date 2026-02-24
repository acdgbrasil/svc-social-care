import Foundation

/// Contrato para o caso de uso de registro de atendimento.
protocol RegisterAppointmentUseCase: Sendable {
    /// Executa o registro de um novo atendimento.
    ///
    /// - Parameter command: O payload com os dados do atendimento.
    /// - Returns: O identificador do atendimento registrado.
    /// - Throws: `RegisterAppointmentError` em caso de erro de validação ou persistência.
    func execute(command: RegisterAppointmentCommand) async throws(RegisterAppointmentError) -> String
}
