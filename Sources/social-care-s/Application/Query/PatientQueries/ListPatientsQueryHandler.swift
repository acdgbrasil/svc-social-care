import Foundation

// MARK: - Query

public struct ListPatientsQuery: Query {
    public typealias Result = PatientListQueryDTO

    public let search: String?
    public let status: String?
    public let cursor: String?
    public let limit: Int

    public init(search: String? = nil, status: String? = nil, cursor: String? = nil, limit: Int = 20) {
        self.search = search
        self.status = status
        self.cursor = cursor
        self.limit = limit
    }
}

// MARK: - Result DTO

public struct PatientListQueryDTO: Codable, Sendable {
    public let items: [PatientSummaryDTO]
    public let totalCount: Int
    public let hasMore: Bool
    public let nextCursor: String?

    public init(items: [PatientSummaryDTO], totalCount: Int, hasMore: Bool, nextCursor: String?) {
        self.items = items
        self.totalCount = totalCount
        self.hasMore = hasMore
        self.nextCursor = nextCursor
    }
}

public struct PatientSummaryDTO: Codable, Sendable {
    public let patientId: String
    public let personId: String
    public let firstName: String?
    public let lastName: String?
    public let fullName: String?
    public let primaryDiagnosis: String?
    public let memberCount: Int
    public let status: String

    public init(from summary: PatientSummary) {
        self.patientId = summary.patientId.description
        self.personId = summary.personId.description
        self.firstName = summary.firstName
        self.lastName = summary.lastName
        if let first = summary.firstName, let last = summary.lastName {
            self.fullName = "\(first) \(last)"
        } else {
            self.fullName = summary.firstName ?? summary.lastName
        }
        self.primaryDiagnosis = summary.primaryDiagnosis
        self.memberCount = summary.memberCount
        self.status = summary.status.rawValue
    }
}

// MARK: - Error

public enum ListPatientsError: Error, Sendable, Equatable {
    case invalidCursorFormat
    case invalidLimit
    case invalidStatusFilter(String)
}

extension ListPatientsError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/query"
    private static let codePrefix = "QLP"

    public var asAppError: AppError {
        switch self {
        case .invalidCursorFormat:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "The cursor format is invalid. Expected a valid patient UUID.",
                bc: Self.bc, module: Self.module, kind: "InvalidCursorFormat",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .dataConsistencyIncident, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-001"], tags: ["layer": "query"]
                ),
                http: 400
            )
        case .invalidLimit:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "The limit must be between 1 and 100.",
                bc: Self.bc, module: Self.module, kind: "InvalidLimit",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .dataConsistencyIncident, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-002"], tags: ["layer": "query"]
                ),
                http: 400
            )
        case .invalidStatusFilter(let value):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "Status filter inválido: '\(value)'. Valores aceitos: active, discharged.",
                bc: Self.bc, module: Self.module, kind: "InvalidStatusFilter",
                context: [:], safeContext: [:],
                observability: .init(
                    category: .dataConsistencyIncident, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-003"], tags: ["layer": "query"]
                ),
                http: 400
            )
        }
    }
}

// MARK: - Handler

public struct ListPatientsQueryHandler: QueryHandling {
    public typealias Q = ListPatientsQuery
    private let repository: any PatientRepository

    public init(repository: any PatientRepository) {
        self.repository = repository
    }

    public func handle(_ query: ListPatientsQuery) async throws -> PatientListQueryDTO {
        guard query.limit >= 1 && query.limit <= 100 else {
            throw ListPatientsError.invalidLimit
        }

        // Parse status filter
        let status: PatientStatus?
        if let statusStr = query.status {
            guard let parsed = PatientStatus(rawValue: statusStr) else {
                throw ListPatientsError.invalidStatusFilter(statusStr)
            }
            status = parsed
        } else {
            status = nil
        }

        let cursor: PatientId?
        if let cursorStr = query.cursor {
            guard let validCursor = try? PatientId(cursorStr) else {
                throw ListPatientsError.invalidCursorFormat
            }
            cursor = validCursor
        } else {
            cursor = nil
        }

        let result = try await repository.list(
            search: query.search,
            status: status,
            cursor: cursor,
            limit: query.limit
        )

        let items = result.items.map { PatientSummaryDTO(from: $0) }

        return PatientListQueryDTO(
            items: items,
            totalCount: result.totalCount,
            hasMore: result.hasMore,
            nextCursor: result.nextCursor?.description
        )
    }
}
