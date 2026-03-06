import Foundation

public struct GetPatientByIdQuery: Query {
    public typealias Result = PatientQueryDTO
    public let patientId: PatientId
    
    public init(patientId: PatientId) {
        self.patientId = patientId
    }
}

public enum GetPatientByIdError: Error, Equatable {
    case patientNotFound
}

public struct GetPatientByIdQueryHandler: QueryHandling {
    public typealias Q = GetPatientByIdQuery
    private let repository: any PatientRepository
    
    public init(repository: any PatientRepository) {
        self.repository = repository
    }
    
    public func handle(_ query: GetPatientByIdQuery) async throws -> PatientQueryDTO {
        guard let patient = try await repository.find(byId: query.patientId) else {
            throw GetPatientByIdError.patientNotFound
        }
        
        return PatientQueryDTO(from: patient)
    }
}
