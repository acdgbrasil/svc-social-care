import Foundation

extension UpdateHousingConditionService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> UpdateHousingConditionError {
        if let e = error as? UpdateHousingConditionError {
            return e
        }
        
        if let e = error as? HousingConditionError {
            switch e {
            case .negativeRooms: return .negativeRooms
            case .negativeBathrooms: return .negativeBathrooms
            case .bathroomsExceedRooms: return .bathroomsExceedRooms
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
