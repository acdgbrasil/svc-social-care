import Foundation

extension AddFamilyMemberCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String? = nil) -> AddFamilyMemberError {
        if let e = error as? AddFamilyMemberError {
            return e
        }
        
        if error is PIDError {
            return .invalidPersonIdFormat
        }
        
        return .persistenceMappingFailure(
            patientId: patientId,
            issues: [String(describing: error)],
            issueCount: 1
        )
    }
}
