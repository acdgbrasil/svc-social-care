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
                return .patientNotActive(reason: "o paciente está na lista de espera. Admita o paciente antes de realizar alterações.")
            case .patientIsDischarged:
                return .patientNotActive(reason: "o paciente está desligado. Readmita o paciente antes de realizar alterações.")
            case .familyMemberAlreadyExists(let memberId):
                return .memberAlreadyExists(memberId)
            default:
                break
            }
        }

        return .persistenceMappingFailure(
            patientId: patientId,
            issues: [String(describing: error)],
            issueCount: 1
        )
    }
}
