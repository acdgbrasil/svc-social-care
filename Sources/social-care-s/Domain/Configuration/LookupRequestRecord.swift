import Foundation

/// Registro de uma solicitacao de novo item em lookup table.
public struct LookupRequestRecord: Sendable {
    public let id: UUID
    public let tableName: String
    public let codigo: String
    public let descricao: String
    public let justificativa: String
    public let status: LookupRequestStatus
    public let requestedBy: String
    public let requestedAt: Date
    public let reviewedBy: String?
    public let reviewedAt: Date?
    public let reviewNote: String?

    public init(
        id: UUID,
        tableName: String,
        codigo: String,
        descricao: String,
        justificativa: String,
        status: LookupRequestStatus,
        requestedBy: String,
        requestedAt: Date,
        reviewedBy: String? = nil,
        reviewedAt: Date? = nil,
        reviewNote: String? = nil
    ) {
        self.id = id
        self.tableName = tableName
        self.codigo = codigo
        self.descricao = descricao
        self.justificativa = justificativa
        self.status = status
        self.requestedBy = requestedBy
        self.requestedAt = requestedAt
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
        self.reviewNote = reviewNote
    }
}
