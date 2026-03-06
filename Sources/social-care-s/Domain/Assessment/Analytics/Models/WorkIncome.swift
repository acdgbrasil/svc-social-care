import Foundation

/// Modelo auxiliar para processamento analítico de renda no domínio.
public struct WorkIncome: Sendable {
    public let memberId: PersonId
    public let monthlyAmount: Double
    
    public init(memberId: PersonId, monthlyAmount: Double) {
        self.memberId = memberId
        self.monthlyAmount = monthlyAmount
    }
}
