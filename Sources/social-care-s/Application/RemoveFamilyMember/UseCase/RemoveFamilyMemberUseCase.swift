import Foundation

/// Contrato para o caso de uso de remoção de membro familiar.
protocol RemoveFamilyMemberUseCase: Sendable {
    /// Executa a remoção de um membro familiar.
    ///
    /// - Parameter command: O payload com os IDs necessários.
    /// - Throws: `RemoveFamilyMemberError` em caso de erro de validação ou persistência.
    func execute(command: RemoveFamilyMemberCommand) async throws(RemoveFamilyMemberError)
}
