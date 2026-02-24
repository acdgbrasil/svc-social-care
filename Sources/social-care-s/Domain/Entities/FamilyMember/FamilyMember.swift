import Foundation

/// Representa um membro da família de um paciente no contexto de assistência social.
public struct FamilyMember: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    /// O identificador único da pessoa (compartilhado globalmente).
    public let personId: PersonId
    
    /// O grau de parentesco ou relacionamento com o paciente.
    public let relationship: String
    
    /// Indica se esta pessoa é a principal cuidadora do paciente.
    public private(set) var isPrimaryCaregiver: Bool
    
    /// Indica se a pessoa reside na mesma habitação que o paciente.
    public let residesWithPatient: Bool

    /// Inicializa um novo membro familiar validando as regras de negócio.
    /// - Parameters:
    ///   - personId: O ID da pessoa.
    ///   - relationship: O parentesco (não pode ser vazio).
    ///   - isPrimaryCaregiver: Flag de cuidador.
    ///   - residesWithPatient: Flag de residência.
    /// - Throws: `FamilyMemberError.invalidRelationship` se o relacionamento for inválido.
    public init(
        personId: PersonId,
        relationship: String,
        isPrimaryCaregiver: Bool,
        residesWithPatient: Bool
    ) throws {
        let trimmedRelationship = relationship.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedRelationship.isEmpty else {
            throw FamilyMemberError.invalidRelationship
        }

        self.personId = personId
        self.relationship = trimmedRelationship
        self.isPrimaryCaregiver = isPrimaryCaregiver
        self.residesWithPatient = residesWithPatient
    }

    // MARK: - Mutators (Idiomatic Swift)

    public mutating func assignAsPrimaryCaregiver() {
        self.isPrimaryCaregiver = true
    }

    public mutating func revokePrimaryCaregiver() {
        self.isPrimaryCaregiver = false
    }

    // MARK: - Equatable
    
    public static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        return lhs.personId == rhs.personId
    }
}
