import Foundation

/// Erros relacionados ao Value Object LookupId.
public enum LookupIdError: Error, Equatable, Sendable {
    case invalidFormat(String)
}
