import Foundation 

/// Um Value Object que representa um identificador único de pessoa (PersonId).
public struct PersonId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {

    public static let brand = "PERSON_ID"
    private let value: String
    public var description: String { value }
    
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw PIDError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
