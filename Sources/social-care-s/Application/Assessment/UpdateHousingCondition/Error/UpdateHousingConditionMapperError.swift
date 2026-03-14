import Foundation

extension UpdateHousingConditionCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String? = nil) -> UpdateHousingConditionError {
        if let e = error as? UpdateHousingConditionError {
            return e
        }
        
        if let e = error as? HousingConditionError {
            switch e {
            case .negativeRooms: return .negativeRooms
            case .negativeBedrooms: return .negativeBedrooms
            case .negativeBathrooms: return .negativeBathrooms
            case .bedroomsExceedRooms: return .bedroomsExceedRooms
            case .bathroomsExceedRooms: return .bathroomsExceedRooms
            }
        }
        
        if let e = error as? PatientIdError {
            switch e {
            case .invalidFormat(let value):
                return .invalidPersonIdFormat(value)
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
