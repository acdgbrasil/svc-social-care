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

    /// Inicializa um rendimento individual validado.
    ///
    /// - Throws: `WorkIncomeError.negativeMonthlyAmount` se o valor for negativo.
    public init(memberId: PersonId, occupationId: LookupId, hasWorkCard: Bool, monthlyAmount: Double) throws {
        guard monthlyAmount >= 0 else {
            throw WorkIncomeError.negativeMonthlyAmount
        }
        self.memberId = memberId
        self.occupationId = occupationId
        self.hasWorkCard = hasWorkCard
        self.monthlyAmount = monthlyAmount
    }
}

public enum WorkIncomeError: Error, Sendable, Equatable {
    case negativeMonthlyAmount
}

extension WorkIncomeError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/work-income"
    private static let codePrefix = "WI"

    public var asAppError: AppError {
        switch self {
        case .negativeMonthlyAmount:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O rendimento mensal nao pode ser negativo.",
                bc: Self.bc, module: Self.module, kind: "NegativeMonthlyAmount",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "work_income"]),
                http: 422
            )
        }
    }
}
