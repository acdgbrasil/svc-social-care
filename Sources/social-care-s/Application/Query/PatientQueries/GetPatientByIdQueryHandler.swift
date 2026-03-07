import Foundation

public struct GetPatientByIdQuery: Query {
    public typealias Result = PatientQueryDTO
    public let patientId: PatientId
    
    public init(patientId: PatientId) {
        self.patientId = patientId
    }
}

public enum GetPatientByIdError: Error, Sendable, Equatable {
    case patientNotFound
}

extension GetPatientByIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/query"
    private static let codePrefix = "QPB"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Patient not found for the given ID.",
                bc: Self.bc, module: Self.module, kind: "PatientNotFound",
                context: [:], safeContext: [:],
                observability: .init(category: .dataConsistencyIncident, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["layer": "query"]),
                http: 404
            )
        }
    }
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
