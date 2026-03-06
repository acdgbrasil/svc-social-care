import Foundation

public struct GetPatientByPersonIdQuery: Query {
    public typealias Result = PatientQueryDTO
    public let personId: String
    
    public init(personId: String) {
        self.personId = personId
    }
}

public enum GetPatientByPersonIdError: Error, Equatable {
    case patientNotFound
    case invalidPersonIdFormat
}

public struct GetPatientByPersonIdQueryHandler: QueryHandling {
    public typealias Q = GetPatientByPersonIdQuery
    private let repository: any PatientRepository
    
    public init(repository: any PatientRepository) {
        self.repository = repository
    }
    
    public func handle(_ query: GetPatientByPersonIdQuery) async throws -> PatientQueryDTO {
        guard let validPersonId = try? PersonId(query.personId) else {
            throw GetPatientByPersonIdError.invalidPersonIdFormat
        }
        
        guard let patient = try await repository.find(byPersonId: validPersonId) else {
            throw GetPatientByPersonIdError.patientNotFound
        }
        
        return PatientQueryDTO(from: patient)
    }
}
