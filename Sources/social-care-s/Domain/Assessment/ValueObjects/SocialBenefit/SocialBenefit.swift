import Foundation

/// Value Object que representa um benefício social individual recebido por um membro da família.
///
/// Encapsula a identificação do benefício, seu valor monetário e o vínculo com um beneficiário.
public struct SocialBenefit: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// O nome descritivo do benefício (ex: "Bolsa Família").
    public let benefitName: String
    
    /// O valor monetário atual do benefício.
    public let amount: Double
    
    /// O identificador único do membro da família que recebe o auxílio.
    public let beneficiaryId: PersonId

    // MARK: - Initializer

    /// Inicializa uma instância validada de benefício social.
    ///
    /// - Throws: `SocialBenefitError` se o nome estiver vazio ou o valor for inválido.
    public init(
        benefitName: String,
        amount: Double,
        beneficiaryId: PersonId
    ) throws {
        let normalizedName = benefitName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !normalizedName.isEmpty else {
            throw SocialBenefitError.benefitNameEmpty
        }

        guard amount > 0 else {
            throw SocialBenefitError.amountInvalid(amount: amount)
        }

        self.benefitName = normalizedName
        self.amount = amount
        self.beneficiaryId = beneficiaryId
    }
}
