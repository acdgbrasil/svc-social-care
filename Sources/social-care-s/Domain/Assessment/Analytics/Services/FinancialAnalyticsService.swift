import Foundation

/// Serviço de Domínio responsável por consolidar indicadores financeiros da família.
///
/// Aplica as fórmulas oficiais do SUAS para cálculo de renda familiar total e per capita,
/// diferenciando rendimentos do trabalho de benefícios de programas sociais.
public struct FinancialAnalyticsService: Sendable {
    
    // MARK: - Nested Types
    
    /// Conjunto de indicadores financeiros projetados.
    public struct Indicators: Sendable {
        /// Renda Total Familiar (Trabalho) - RTF_S.
        public let totalWorkIncome: Double
        /// Renda Per Capita (Trabalho) - RPC_S.
        public let perCapitaWorkIncome: Double
        /// Renda Total Global (Trabalho + Benefícios) - RTG.
        public let totalGlobalIncome: Double
        /// Renda Per Capita Global (Trabalho + Benefícios) - RPC_G.
        public let perCapitaGlobalIncome: Double
    }
    
    // MARK: - Analytics Logic

    /// Calcula os indicadores econômicos da família.
    ///
    /// - Parameters:
    ///   - workIncomes: Lista de rendimentos individuais do trabalho.
    ///   - socialBenefits: Lista de benefícios sociais recebidos.
    ///   - memberCount: Total de membros da família (divisor para per capita).
    /// - Returns: Uma estrutura `Indicators` com os valores consolidados.
    public static func calculate(
        workIncomes: [WorkIncome],
        socialBenefits: [SocialBenefit],
        memberCount: Int
    ) -> Indicators {
        let totalMembers = max(memberCount, 1)
        let divisor = Double(totalMembers)
        
        let totalWork = workIncomes.reduce(0.0) { $0 + $1.monthlyAmount }
        let totalBenefits = socialBenefits.reduce(0.0) { $0 + $1.amount }
        let totalGlobal = totalWork + totalBenefits
        
        return Indicators(
            totalWorkIncome: totalWork,
            perCapitaWorkIncome: totalWork / divisor,
            totalGlobalIncome: totalGlobal,
            perCapitaGlobalIncome: totalGlobal / divisor
        )
    }
}
