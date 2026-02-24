import Foundation

/// Um Value Object que representa a situação socioeconômica de uma família.
///
/// Consolida informações sobre renda total, renda per capita, benefícios sociais,
/// fonte de renda e situação de emprego dos membros.
public struct SocioEconomicSituation: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Renda mensal total da família.
    public let totalFamilyIncome: Double
    
    /// Renda calculada por pessoa da família.
    public let incomePerCapita: Double
    
    /// Indica se a família recebe algum benefício social.
    public let receivesSocialBenefit: Bool
    
    /// Coleção detalhada dos benefícios sociais recebidos.
    public let socialBenefits: SocialBenefitsCollection
    
    /// A principal fonte de renda da família.
    public let mainSourceOfIncome: String
    
    /// Indica se há algum membro da família desempregado.
    public let hasUnemployed: Bool

    // MARK: - Initializer

    /// Inicializa uma instância validada de `SocioEconomicSituation`.
    ///
    /// - Throws: `SocioEconomicSituationError` em caso de erro de validação.
    public init(
        totalFamilyIncome: Double,
        incomePerCapita: Double,
        receivesSocialBenefit: Bool,
        socialBenefits: SocialBenefitsCollection,
        mainSourceOfIncome: String,
        hasUnemployed: Bool
    ) throws {
        
        // Validação: Coerência entre a flag e a coleção de benefícios
        guard !(receivesSocialBenefit == false && !socialBenefits.isEmpty) else {
            throw SocioEconomicSituationError.inconsistentSocialBenefit
        }

        guard !(receivesSocialBenefit == true && socialBenefits.isEmpty) else {
            throw SocioEconomicSituationError.missingSocialBenefits
        }

        // Validação: Rendas negativas
        guard totalFamilyIncome >= 0 else {
            throw SocioEconomicSituationError.negativeFamilyIncome(amount: totalFamilyIncome)
        }

        guard incomePerCapita >= 0 else {
            throw SocioEconomicSituationError.negativeIncomePerCapita(amount: incomePerCapita)
        }

        // Validação: Coerência entre per capita e total
        guard incomePerCapita <= totalFamilyIncome else {
            throw SocioEconomicSituationError.inconsistentIncomePerCapita(perCapita: incomePerCapita, total: totalFamilyIncome)
        }

        let trimmedSource = mainSourceOfIncome.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validação: Fonte de renda vazia
        guard !trimmedSource.isEmpty else {
            throw SocioEconomicSituationError.emptyMainSourceOfIncome
        }

        self.totalFamilyIncome = totalFamilyIncome
        self.incomePerCapita = incomePerCapita
        self.receivesSocialBenefit = receivesSocialBenefit
        self.socialBenefits = socialBenefits
        self.mainSourceOfIncome = trimmedSource
        self.hasUnemployed = hasUnemployed
    }
}
