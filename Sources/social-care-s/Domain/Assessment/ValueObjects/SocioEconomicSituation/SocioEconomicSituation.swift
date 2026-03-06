import Foundation

/// Value Object que representa a situação socioeconômica de um núcleo familiar.
///
/// Consolida indicadores de renda, acesso a benefícios e estabilidade empregatícia,
/// permitindo a classificação de vulnerabilidade econômica para fins de auxílio social.
public struct SocioEconomicSituation: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Soma de todos os rendimentos brutos dos membros residentes.
    public let totalFamilyIncome: Double
    
    /// Renda média por pessoa (calculada pelo domínio).
    public let incomePerCapita: Double
    
    /// Flag indicativa de recebimento de auxílios governamentais.
    public let receivesSocialBenefit: Bool
    
    /// Coleção detalhada de cada benefício recebido.
    public let socialBenefits: SocialBenefitsCollection
    
    /// Descrição da fonte de sustento (ex: "Trabalho Informal", "Aposentadoria").
    public let mainSourceOfIncome: String
    
    /// Indica se há membros em idade ativa sem colocação no mercado de trabalho.
    public let hasUnemployed: Bool

    // MARK: - Initializer

    /// Inicializa uma situação socioeconômica validada.
    ///
    /// - Throws: `SocioEconomicSituationError` se houver inconsistência entre flags e lista de benefícios,
    ///   ou se os valores monetários forem negativos.
    public init(
        totalFamilyIncome: Double,
        incomePerCapita: Double,
        receivesSocialBenefit: Bool,
        socialBenefits: SocialBenefitsCollection,
        mainSourceOfIncome: String,
        hasUnemployed: Bool
    ) throws {
        
        // Validação de Coerência: se diz que recebe, a lista não pode ser vazia
        guard !(receivesSocialBenefit == false && !socialBenefits.isEmpty) else {
            throw SocioEconomicSituationError.inconsistentSocialBenefit
        }

        guard !(receivesSocialBenefit == true && socialBenefits.isEmpty) else {
            throw SocioEconomicSituationError.missingSocialBenefits
        }

        guard totalFamilyIncome >= 0 else {
            throw SocioEconomicSituationError.negativeFamilyIncome(amount: totalFamilyIncome)
        }

        guard incomePerCapita >= 0 else {
            throw SocioEconomicSituationError.negativeIncomePerCapita(amount: incomePerCapita)
        }

        // A renda per capita nunca pode ser maior que a total (matematicamente impossível em famílias de n >= 1)
        guard incomePerCapita <= totalFamilyIncome else {
            throw SocioEconomicSituationError.inconsistentIncomePerCapita(perCapita: incomePerCapita, total: totalFamilyIncome)
        }

        let trimmedSource = mainSourceOfIncome.trimmingCharacters(in: .whitespacesAndNewlines)
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
