import Foundation

/// Value Object que representa o identificador único de um profissional.
///
/// Usado para identificar assistentes sociais, médicos e outros agentes
/// responsáveis por intervenções e atendimentos.
public struct ProfessionalId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {
    
    // MARK: - Constants
    
    /// Marca semântica do identificador.
    public static let brand = "PROFESSIONAL_ID"
    
    // MARK: - Properties
    
    /// O valor bruto do identificador.
    private let value: String
    
    /// Retorna a representação em string (lowercased UUID).
    public var description: String { value }
    
    // MARK: - Initializers
    
    /// Inicializa um `ProfessionalId` a partir de uma string UUID existente.
    ///
    /// - Parameter rawValue: A string UUID que será normalizada para minúsculas.
    /// - Throws: `ProfessionalIdError.invalidFormat` se o valor não for um UUID válido.
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw ProfessionalIdError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    /// Cria um novo `ProfessionalId` com um identificador único gerado aleatoriamente.
    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
