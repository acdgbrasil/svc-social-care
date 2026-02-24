import Foundation

extension CreateReferralService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> CreateReferralError {
        if let e = error as? CreateReferralError {
            return e
        }
        
        if let e = error as? PatientError {
            switch e {
            case .referralTargetOutsideBoundary(let targetId):
                return .targetOutsideBoundary(targetId)
            default:
                break
            }
        }
        
        if let e = error as? ReferralError {
            switch e {
            case .dateInFuture:
                return .dateInFuture
            case .reasonMissing:
                return .reasonMissing
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
        
        if let e = error as? ProfessionalIdError {
            switch e {
            case .invalidFormat(let value):
                return .invalidProfessionalIdFormat(value)
            }
        }
        
        if let e = error as? ReferralIdError {
            switch e {
            case .invalidFormat(let value):
                return .invalidReferralIdFormat(value)
            }
        }
        
        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
