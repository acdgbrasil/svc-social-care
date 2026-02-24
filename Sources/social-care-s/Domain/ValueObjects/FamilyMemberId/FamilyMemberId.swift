import Foundation

/// Um Value Object que representa o identificador único de um membro da família.
public struct FamilyMemberId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {

    public static let brand = "FamilyMemberId"
    private let value: String
    public var description: String { value }
    
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw FamilyMemberIdError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    public init() {
        self.value = UUID().uuidString.lowercased()
    }

    public static func equals(_ id1: FamilyMemberId, _ id2: FamilyMemberId) -> Bool {
        return id1.value == id2.value
    }
    
    public static func toString(_ id: FamilyMemberId) -> String {
        return id.value
    }
}
