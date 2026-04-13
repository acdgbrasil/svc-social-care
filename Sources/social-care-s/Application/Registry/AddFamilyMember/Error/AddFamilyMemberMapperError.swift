import Foundation

extension AddFamilyMemberCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String? = nil) -> AddFamilyMemberError {
        if let e = error as? AddFamilyMemberError {
            return e
        }
        
        if error is PatientIdError {
            return .invalidPersonIdFormat
        }

        if error is PIDError {
            return .invalidPersonIdFormat
        }

        if let e = error as? PatientError {
            switch e {
            case .patientIsWaitlisted:
                return .patientNotActive(reason: "PATIENT_IS_WAITLISTED")
            case .patientIsDischarged:
                return .patientNotActive(reason: "PATIENT_IS_DISCHARGED")
            case .familyMemberAlreadyExists(let memberId):
                return .memberAlreadyExists(memberId)
            default:
                return .persistenceMappingFailure(patientId: patientId, issues: [String(describing: e)], issueCount: 1)
            }
        }

        return .persistenceMappingFailure(
            patientId: patientId,
            issues: [String(describing: error)],
            issueCount: 1
        )
    }
}
