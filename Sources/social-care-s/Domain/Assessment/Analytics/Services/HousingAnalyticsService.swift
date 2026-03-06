import Foundation

/// Serviço de Domínio para análise de habitabilidade.
public struct HousingAnalyticsService: Sendable {
    
    /// Calcula a densidade habitacional (pessoas por dormitório).
    /// - Parameters:
    ///   - members: Total de membros na família.
    ///   - bedrooms: Total de dormitórios na residência.
    /// - Returns: O valor da densidade.
    public static func density(forMembers members: Int, inBedrooms bedrooms: Int) -> Double {
        let memberCount = Double(max(members, 1))
        let bedroomCount = Double(max(bedrooms, 1))
        return memberCount / bedroomCount
    }
    
    /// Verifica se a densidade indica situação de superlotação (ex: > 3 pessoas/quarto).
    public static func isOvercrowded(members: Int, bedrooms: Int) -> Bool {
        return density(forMembers: members, inBedrooms: bedrooms) > 3.0
    }
}
