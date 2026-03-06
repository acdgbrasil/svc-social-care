import Foundation

extension UpdateSocialIdentityCommandHandler {
    public func mapError(_ error: Error, patientId: String? = nil) -> UpdateSocialIdentityError {
        if let e = error as? UpdateSocialIdentityError { return e }

        if let e = error as? SocialIdentityError {
            switch e {
            case .indigenousInVillageMissingDescription:
                return .indigenousInVillageMissingDescription
            case .indigenousOutsideVillageMissingDescription:
                return .indigenousOutsideVillageMissingDescription
            case .descriptionRequiredForOtherType:
                return .descriptionRequiredForOtherType
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
