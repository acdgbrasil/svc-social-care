import Foundation

/// Value Object para consolidação das condições educacionais da família.
public struct EducationalStatus: Codable, Equatable, Sendable {
    
    public let familyId: PatientId
    public let memberProfiles: [MemberEducationalProfile]
    public let programOccurrences: [ProgramOccurrence]
    
    public init(
        familyId: PatientId,
        memberProfiles: [MemberEducationalProfile],
        programOccurrences: [ProgramOccurrence]
    ) {
        self.familyId = familyId
        self.memberProfiles = memberProfiles
        self.programOccurrences = programOccurrences
    }
}

public struct MemberEducationalProfile: Codable, Equatable, Sendable {
    public let memberId: PersonId
    public let canReadWrite: Bool
    public let attendsSchool: Bool
    /// Identificador do nível de escolaridade (Lookup para dominio_escolaridade).
    public let educationLevelId: LookupId
    
    public init(memberId: PersonId, canReadWrite: Bool, attendsSchool: Bool, educationLevelId: LookupId) {
        self.memberId = memberId
        self.canReadWrite = canReadWrite
        self.attendsSchool = attendsSchool
        self.educationLevelId = educationLevelId
    }
}

public struct ProgramOccurrence: Codable, Equatable, Sendable {
    public let memberId: PersonId
    public let date: TimeStamp
    /// Identificador do efeito (Lookup para dominio_efeito_condicionalidade).
    public let effectId: LookupId
    public let isSuspensionRequested: Bool
    
    public init(memberId: PersonId, date: TimeStamp, effectId: LookupId, isSuspensionRequested: Bool) {
        self.memberId = memberId
        self.date = date
        self.effectId = effectId
        self.isSuspensionRequested = isSuspensionRequested
    }
}
