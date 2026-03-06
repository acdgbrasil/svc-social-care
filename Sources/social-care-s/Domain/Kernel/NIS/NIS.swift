import Foundation

public struct NIS: Codable, Equatable, Hashable, Sendable {
    public let value: String
    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NISError.empty }
        let sanitized = trimmed.filter(\.isNumber)
        guard sanitized.count == 11 else { throw NISError.invalidLength(value: sanitized, expected: 11) }
        self.value = sanitized
    }
}
