import Foundation

extension RegisterPatientCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String? = nil) -> RegisterPatientError {
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
            case .invalidFormat(let value): return .invalidPersonIdFormat(value)
            }
        }

        if let e = error as? PersonalDataError {
            switch e {
            case .firstNameEmpty: return .invalidFirstName
            case .lastNameEmpty: return .invalidLastName
            case .motherNameEmpty: return .invalidMotherName
            case .nationalityEmpty: return .invalidNationality
            case .birthDateInFuture(let date, let now): return .invalidBirthDate(date: date, now: now)
            }
        }

        if let e = error as? CPFError {
            switch e {
            case .empty: return .invalidCPF("EMPTY")
            case .invalidCharacters(let v): return .invalidCPF(v)
            case .invalidLength(let v, _): return .invalidCPF(v)
            case .repeatedDigits(let v): return .invalidCPF(v)
            case .invalidCheckDigits(let v): return .invalidCPF(v)
            }
        }

        if let e = error as? NISError {
            switch e {
            case .empty: return .invalidNIS("EMPTY")
            case .invalidLength(let v, _): return .invalidNIS(v)
            }
        }

        if let e = error as? RGDocumentError {
            switch e {
            case .emptyNumber: return .invalidRGDocument("EMPTY")
            case .invalidNumberFormat(let v): return .invalidRGDocument(v)
            case .invalidCheckDigit(let v, _, _): return .invalidRGDocument(v)
            case .invalidIssuingState(let v): return .invalidRGDocument(v)
            case .emptyIssuingAgency: return .invalidRGDocument("EMPTY_AGENCY")
            case .issueDateInFuture(let v, _): return .invalidRGDocument(v)
            }
        }

        if let e = error as? CivilDocumentsError {
            switch e {
            case .atLeastOneDocumentRequired: return .atLeastOneDocumentRequired
            }
        }

        if let e = error as? SocialIdentityError {
            switch e {
            case .indigenousInVillageMissingDescription: return .indigenousInVillageMissingDescription
            case .indigenousOutsideVillageMissingDescription: return .indigenousOutsideVillageMissingDescription
            case .descriptionRequiredForOtherType: return .descriptionRequiredForOtherType
            }
        }

        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
