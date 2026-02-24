import Foundation

/// Contrato para o caso de uso de criação de encaminhamento.
protocol CreateReferralUseCase: Sendable {
    /// Executa a criação de um novo encaminhamento.
    ///
    /// - Parameter command: O payload com os dados do encaminhamento.
    /// - Returns: O identificador do encaminhamento criado.
    /// - Throws: `CreateReferralError` em caso de erro de validação ou persistência.
    func execute(command: CreateReferralCommand) async throws(CreateReferralError) -> String
}
