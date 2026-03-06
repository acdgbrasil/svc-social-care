import Foundation

/// Value Object que representa um identificador de referência para tabelas de domínio (Lookups).
///
/// Este objeto é a base da arquitetura Metadata-Driven do sistema, permitindo que
/// o domínio referencie conceitos dinâmicos (como tipos de benefícios ou parentescos)
/// sem acoplamento com enums estáticos.
///
/// - Note: Encapsula um UUID em formato canônico (lowercase).
public struct LookupId: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    
    // MARK: - Properties
    
    /// O valor do identificador.
    private let value: String
    
    /// Retorna a representação em string do identificador (lowercased UUID).
    public var description: String { value }
    
    // MARK: - Initializers
    
    /// Inicializa um `LookupId` a partir de uma string UUID.
    ///
    /// - Parameter id: A string contendo o UUID.
    /// - Throws: `LookupIdError.invalidFormat` se a string não for um UUID válido.
    public init(_ id: String) throws {
        let sanitized = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw LookupIdError.invalidFormat(id)
        }
        self.value = sanitized
    }
    
    // MARK: - Codable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
