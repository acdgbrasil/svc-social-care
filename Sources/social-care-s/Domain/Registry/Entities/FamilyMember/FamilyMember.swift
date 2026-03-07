import Foundation

/// Representa um membro da família de um paciente no contexto de assistência social.
public struct FamilyMember: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    /// O identificador único da pessoa (compartilhado globalmente).
    public let personId: PersonId
    
    /// O identificador do grau de parentesco (FK para dominio_parentesco).
    public let relationshipId: LookupId
    
    /// Indica se esta pessoa é a principal cuidadora do paciente.
    public private(set) var isPrimaryCaregiver: Bool
    
    /// Indica se a pessoa reside na mesma habitação que o paciente.
    public let residesWithPatient: Bool

    /// Indica se o membro possui alguma deficiência.
    public let hasDisability: Bool

    /// Documentos pessoais solicitados para este membro. Sem duplicatas.
    public let requiredDocuments: [RequiredDocument]
    
    /// Data de nascimento para cálculos analíticos de idade.
    public let birthDate: TimeStamp

    /// Inicializa um novo membro familiar.
    public init(
        personId: PersonId,
        relationshipId: LookupId,
        isPrimaryCaregiver: Bool,
        residesWithPatient: Bool,
        hasDisability: Bool = false,
        requiredDocuments: [RequiredDocument] = [],
        birthDate: TimeStamp
    ) {
        self.personId = personId
        self.relationshipId = relationshipId
        self.isPrimaryCaregiver = isPrimaryCaregiver
        self.residesWithPatient = residesWithPatient
        self.hasDisability = hasDisability
        self.requiredDocuments = Array(Set(requiredDocuments))
            .sorted { $0.rawValue < $1.rawValue }
        self.birthDate = birthDate
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
