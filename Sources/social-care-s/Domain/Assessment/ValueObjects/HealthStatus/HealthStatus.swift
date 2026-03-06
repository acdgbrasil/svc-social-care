import Foundation

/// Value Object que consolida as condições de saúde da família.
public struct HealthStatus: Codable, Equatable, Sendable {
    
    public let familyId: PatientId
    public let deficiencies: [MemberDeficiency]
    public let gestatingMembers: [PregnantMember]
    public let constantCareNeeds: [PersonId]
    public let foodInsecurity: Bool
    
    public init(
        familyId: PatientId,
        deficiencies: [MemberDeficiency],
        gestatingMembers: [PregnantMember],
        constantCareNeeds: [PersonId],
        foodInsecurity: Bool
    ) {
        self.familyId = familyId
        self.deficiencies = deficiencies
        self.gestatingMembers = gestatingMembers
        self.constantCareNeeds = constantCareNeeds
        self.foodInsecurity = foodInsecurity
    }
}

public struct MemberDeficiency: Codable, Equatable, Sendable {
    public let memberId: PersonId
    public let deficiencyTypeId: LookupId // Tabela domínio
    public let needsConstantCare: Bool
    public let responsibleCaregiverName: String?
    
    public init(memberId: PersonId, deficiencyTypeId: LookupId, needsConstantCare: Bool, responsibleCaregiverName: String?) {
        self.memberId = memberId
        self.deficiencyTypeId = deficiencyTypeId
        self.needsConstantCare = needsConstantCare
        self.responsibleCaregiverName = responsibleCaregiverName
    }
}

public struct PregnantMember: Codable, Equatable, Sendable {
    public let memberId: PersonId
    public let monthsGestation: Int
    public let startedPrenatalCare: Bool
    
    public init(memberId: PersonId, monthsGestation: Int, startedPrenatalCare: Bool) {
        self.memberId = memberId
        self.monthsGestation = monthsGestation
        self.startedPrenatalCare = startedPrenatalCare
    }
}
