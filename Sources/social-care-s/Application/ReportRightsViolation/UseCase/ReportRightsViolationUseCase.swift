import Foundation

/// Contrato para o caso de uso de relato de violação de direitos.
protocol ReportRightsViolationUseCase: Sendable {
    /// Executa o registro de um relato de violação de direitos.
    ///
    /// - Parameter command: O payload com os dados da violação.
    /// - Returns: O identificador do relatório criado.
    /// - Throws: `ReportRightsViolationError` em caso de erro de validação ou persistência.
    func execute(command: ReportRightsViolationCommand) async throws(ReportRightsViolationError) -> String
}
