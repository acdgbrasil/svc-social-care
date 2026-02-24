import Foundation

extension AssignPrimaryCaregiverService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> AssignPrimaryCaregiverError {
        if let e = error as? AssignPrimaryCaregiverError {
            return e
        }
        
        if let e = error as? PatientError {
            switch e {
            case .familyMemberNotFound(let personId):
                return .familyMemberNotFound(personId: personId)
            default:
                break
            }
        }
        
        if let e = error as? PIDError {
            switch e {
            case .invalidFormat(let value):
                return .invalidPersonIdFormat(value)
            }
        }
        
        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
