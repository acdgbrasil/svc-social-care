import Foundation

/// Contrato para o caso de uso de atualização das condições de moradia.
protocol UpdateHousingConditionUseCase: Sendable {
    /// Executa a atualização das condições de moradia.
    ///
    /// - Parameter command: O payload com os novos dados.
    /// - Throws: `UpdateHousingConditionError` em caso de erro de validação ou persistência.
    func execute(command: UpdateHousingConditionCommand) async throws(UpdateHousingConditionError)
}
