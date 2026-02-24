import Foundation

/// Representa um membro da família de um paciente.
public struct FamilyMember: Codable, Equatable, Sendable {
    
    // MARK: - Properties
    
    public let id: FamilyMemberId
    public let personId: PersonId
    public let relationship: String
    public private(set) var isPrimaryCaregiver: Bool
    public let residesWithPatient: Bool

    // MARK: - Initializer
    
    private init(
        id: FamilyMemberId,
        personId: PersonId,
        relationship: String,
        isPrimaryCaregiver: Bool,
        residesWithPatient: Bool
    ) {
        self.id = id
        self.personId = personId
        self.relationship = relationship
        self.isPrimaryCaregiver = isPrimaryCaregiver
        self.residesWithPatient = residesWithPatient
    }

    // MARK: - Factory Method

    public static func create(
        id: FamilyMemberId,
        personId: PersonId,
        relationship: String,
        isPrimaryCaregiver: Bool,
        residesWithPatient: Bool
    ) throws -> FamilyMember {
        
        let trimmedRelationship = relationship.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedRelationship.isEmpty else {
            throw FamilyMemberError.invalidRelationship
        }

        return FamilyMember(
            id: id,
            personId: personId,
            relationship: trimmedRelationship,
            isPrimaryCaregiver: isPrimaryCaregiver,
            residesWithPatient: residesWithPatient
        )
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
        return lhs.id == rhs.id
    }
}
