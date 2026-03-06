import Foundation 

/// Value Object que representa o identificador único global de uma pessoa (PersonId).
///
/// Utiliza o padrão UUID para garantir a unicidade entre diferentes microsserviços
/// e contextos de domínio no hardware dedicado.
public struct PersonId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {

    // MARK: - Constants
    
    /// Marca semântica do identificador.
    public static let brand = "PERSON_ID"
    
    // MARK: - Properties
    
    /// O valor bruto do identificador.
    private let value: String
    
    /// Retorna a representação em string (lowercased UUID).
    public var description: String { value }
    
    // MARK: - Initializers
    
    /// Inicializa um `PersonId` a partir de uma string UUID existente.
    ///
    /// - Parameter rawValue: A string UUID que será normalizada para minúsculas.
    /// - Throws: `PIDError.invalidFormat` se o valor não for um UUID válido.
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw PIDError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    /// Cria um novo `PersonId` com um identificador único gerado aleatoriamente.
    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
