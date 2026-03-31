import Foundation

// MARK: - Query

public struct ListLookupRequestsQuery: Query {
    public typealias Result = [LookupRequestDTO]

    public let status: String?
    public let requestedBy: String?

    public init(status: String? = nil, requestedBy: String? = nil) {
        self.status = status
        self.requestedBy = requestedBy
    }
}

// MARK: - DTO

public struct LookupRequestDTO: Codable, Sendable {
    public let id: String
    public let tableName: String
    public let codigo: String
    public let descricao: String
    public let justificativa: String
    public let status: String
    public let requestedBy: String
    public let requestedAt: Date
    public let reviewedBy: String?
    public let reviewedAt: Date?
    public let reviewNote: String?

    public init(from record: LookupRequestRecord) {
        self.id = record.id.uuidString
        self.tableName = record.tableName
        self.codigo = record.codigo
        self.descricao = record.descricao
        self.justificativa = record.justificativa
        self.status = record.status.rawValue
        self.requestedBy = record.requestedBy
        self.requestedAt = record.requestedAt
        self.reviewedBy = record.reviewedBy
        self.reviewedAt = record.reviewedAt
        self.reviewNote = record.reviewNote
    }
}

// MARK: - Handler

public struct ListLookupRequestsQueryHandler: QueryHandling {
    public typealias Q = ListLookupRequestsQuery
    private let repository: any LookupRequestRepository

    public init(repository: any LookupRequestRepository) {
        self.repository = repository
    }

    public func handle(_ query: ListLookupRequestsQuery) async throws -> [LookupRequestDTO] {
        let records = try await repository.list(status: query.status, requestedBy: query.requestedBy)
        return records.map { LookupRequestDTO(from: $0) }
    }
}
