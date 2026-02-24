import Foundation

extension AddFamilyMemberService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> AddFamilyMemberError {
        if let e = error as? AddFamilyMemberError {
            return e
        }
        
        if let e = error as? PIDError {
            return .invalidPersonIdFormat
        }
        
        return .persistenceMappingFailure(
            patientId: patientId,
            issues: [String(describing: error)],
            issueCount: 1
        )
    }
}
