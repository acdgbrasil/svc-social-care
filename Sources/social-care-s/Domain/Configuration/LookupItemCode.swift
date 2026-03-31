import Foundation

/// Value Object que valida e encapsula um codigo de item de lookup (UPPER_SNAKE_CASE).
public struct LookupItemCode: Sendable, Equatable, Hashable, CustomStringConvertible {

    public let value: String
    public var description: String { value }

    public init(_ raw: String) throws {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty, Self.isUpperSnakeCase(trimmed) else {
            throw LookupItemCodeError.invalidFormat(raw)
        }
        self.value = trimmed
    }

    private static func isUpperSnakeCase(_ s: String) -> Bool {
        let allowed = CharacterSet.uppercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "_"))

        guard CharacterSet.uppercaseLetters.contains(Unicode.Scalar(String(s.first!))!) else {
            return false
        }
        guard !s.contains("__") && !s.hasSuffix("_") else { return false }
        return s.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

public enum LookupItemCodeError: Error, Sendable, Equatable {
    case invalidFormat(String)
}
