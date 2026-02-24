import Foundation

extension RegisterPatientService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> RegisterPatientError {
        if let e = error as? RegisterPatientError {
            return e
        }
        
        if let e = error as? PatientError {
            switch e {
            case .initialDiagnosesCantBeEmpty:
                return .initialDiagnosesRequired
            default:
                break
            }
        }
        
        if let e = error as? ICDCodeError {
            switch e {
            case .invalidCidNumber(let value, _):
                return .invalidIcdCode(value)
            case .emptyCidCode:
                return .invalidIcdCode("EMPTY")
            }
        }
        
        if let e = error as? DiagnosisError {
            switch e {
            case .dateInFuture(let date, let now):
                return .invalidDiagnosisDate(date: date, now: now)
            case .descriptionEmpty:
                return .emptyDiagnosisDescription
            case .dateBeforeYearZero(let year):
                return .persistenceMappingFailure(issues: ["Invalid year: \(year)"])
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
