import Foundation

/// Contrato para o caso de uso de atualização da situação socioeconômica.
protocol UpdateSocioEconomicSituationUseCase: Sendable {
    /// Executa a atualização da situação socioeconômica.
    ///
    /// - Parameter command: O payload com os novos dados.
    /// - Throws: `UpdateSocioEconomicSituationError` em caso de erro de validação ou persistência.
    func execute(command: UpdateSocioEconomicSituationCommand) async throws(UpdateSocioEconomicSituationError)
}
