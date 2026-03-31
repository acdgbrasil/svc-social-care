import Foundation

/// Status de uma solicitacao de novo item em lookup table.
public enum LookupRequestStatus: String, Sendable, Codable, Equatable {
    case pendente
    case aprovado
    case rejeitado
}
