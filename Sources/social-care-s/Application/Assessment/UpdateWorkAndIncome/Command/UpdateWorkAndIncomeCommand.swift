import Foundation

public struct UpdateWorkAndIncomeCommand: Command {
    public struct IncomeDraft: Sendable {
        public let memberId: String
        public let occupationId: String
        public let hasWorkCard: Bool
        public let monthlyAmount: Double

        public init(memberId: String, occupationId: String, hasWorkCard: Bool, monthlyAmount: Double) {
            self.memberId = memberId
            self.occupationId = occupationId
            self.hasWorkCard = hasWorkCard
            self.monthlyAmount = monthlyAmount
        }
    }

    public struct BenefitDraft: Sendable {
        public let benefitName: String
        public let amount: Double
        public let beneficiaryId: String

        public init(benefitName: String, amount: Double, beneficiaryId: String) {
            self.benefitName = benefitName
            self.amount = amount
            self.beneficiaryId = beneficiaryId
        }
    }

    public let patientId: String
    public let individualIncomes: [IncomeDraft]
    public let socialBenefits: [BenefitDraft]
    public let hasRetiredMembers: Bool
    public let actorId: String

    public init(patientId: String, individualIncomes: [IncomeDraft], socialBenefits: [BenefitDraft], hasRetiredMembers: Bool, actorId: String) {
        self.patientId = patientId
        self.individualIncomes = individualIncomes
        self.socialBenefits = socialBenefits
        self.hasRetiredMembers = hasRetiredMembers
        self.actorId = actorId
    }
}
