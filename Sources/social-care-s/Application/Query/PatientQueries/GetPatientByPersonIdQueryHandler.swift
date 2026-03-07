import Foundation

public struct GetPatientByPersonIdQuery: Query {
    public typealias Result = PatientQueryDTO
    public let personId: String
    
    public init(personId: String) {
        self.personId = personId
    }
}

public enum GetPatientByPersonIdError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat
}

extension GetPatientByPersonIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/query"
    private static let codePrefix = "QPP"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Patient not found for the given person ID.",
                bc: Self.bc, module: Self.module, kind: "PatientNotFound",
                context: [:], safeContext: [:],
                observability: .init(category: .dataConsistencyIncident, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["layer": "query"]),
                http: 404
            )
        case .invalidPersonIdFormat:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "The person ID format is invalid.",
                bc: Self.bc, module: Self.module, kind: "InvalidPersonIdFormat",
                context: [:], safeContext: [:],
                observability: .init(category: .dataConsistencyIncident, severity: .error, fingerprint: ["\(Self.codePrefix)-002"], tags: ["layer": "query"]),
                http: 400
            )
        }
    }
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
