import Foundation

/// Um Value Object que representa um benefício social recebido por um membro da família.
///
/// Encapsula o nome do benefício, o valor monetário e o beneficiário associado.
public struct SocialBenefit: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// O nome do benefício social (ex: "Bolsa Família").
    public let benefitName: String
    
    /// O valor monetário do benefício.
    public let amount: Double
    
    /// O identificador do membro da família que recebe o benefício.
    public let beneficiaryId: PersonId

    // MARK: - Initializer

    /// Inicializa uma instância validada de `SocialBenefit`.
    ///
    /// - Throws: `SocialBenefitError` em caso de erro de validação.
    public init(
        benefitName: String,
        amount: Double,
        beneficiaryId: PersonId
    ) throws {
        
        // Normalização do nome: trim + substituição de múltiplos espaços por um único
        let normalizedName = benefitName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Validação: Nome não pode ser vazio
        guard !normalizedName.isEmpty else {
            throw SocialBenefitError.benefitNameEmpty
        }

        // Validação: Valor deve ser positivo
        guard amount > 0 else {
            throw SocialBenefitError.amountInvalid(amount: amount)
        }

        self.benefitName = normalizedName
        self.amount = amount
        self.beneficiaryId = beneficiaryId
    }
}
