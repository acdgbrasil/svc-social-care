import Foundation

/// Contrato para o caso de uso de atribuição de cuidador principal.
protocol AssignPrimaryCaregiverUseCase: Sendable {
    /// Executa a lógica de atribuição do cuidador principal.
    ///
    /// - Parameter command: O payload de entrada.
    /// - Throws: `AssignPrimaryCaregiverError` em caso de falha de negócio ou técnica.
    func execute(command: AssignPrimaryCaregiverCommand) async throws(AssignPrimaryCaregiverError)
}
