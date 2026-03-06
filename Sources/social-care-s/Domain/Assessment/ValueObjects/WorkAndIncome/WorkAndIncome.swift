import Foundation

/// Value Object que consolida a situação de trabalho e renda da família.
public struct WorkAndIncome: Codable, Equatable, Sendable {
    
    public let familyId: PatientId
    public let individualIncomes: [WorkIncomeVO]
    public let socialBenefits: [SocialBenefit]
    public let hasRetiredMembers: Bool
    
    public init(
        familyId: PatientId,
        individualIncomes: [WorkIncomeVO],
        socialBenefits: [SocialBenefit],
        hasRetiredMembers: Bool
    ) {
        self.familyId = familyId
        self.individualIncomes = individualIncomes
        self.socialBenefits = socialBenefits
        self.hasRetiredMembers = hasRetiredMembers
    }
}

/// Representa o rendimento individual de um membro.
public struct WorkIncomeVO: Codable, Equatable, Sendable {
    public let memberId: PersonId
    /// Identificador da condição de ocupação (Lookup para dominio_condicao_ocupacao).
    public let occupationId: LookupId
    public let hasWorkCard: Bool
    public let monthlyAmount: Double
    
    public init(memberId: PersonId, occupationId: LookupId, hasWorkCard: Bool, monthlyAmount: Double) {
        self.memberId = memberId
        self.occupationId = occupationId
        self.hasWorkCard = hasWorkCard
        self.monthlyAmount = monthlyAmount
    }
}
