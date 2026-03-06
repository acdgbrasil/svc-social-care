import Foundation

/// Serviço de Domínio especializado na identificação de vulnerabilidades educacionais.
///
/// Este serviço projeta dados brutos de escolaridade em indicadores sociais,
/// agrupando faltas de frequência e analfabetismo por faixas etárias críticas do SUAS.
public struct EducationAnalyticsService: Sendable {
    
    // MARK: - Nested Types
    
    /// Faixas etárias de interesse para indicadores educacionais.
    public enum AgeRange: String, Sendable {
        /// Primeira infância (Creche/Pré-escola).
        case range0to5
        /// Ensino Fundamental I e II.
        case range6to14
        /// Ensino Médio e transição para vida adulta.
        case range15to17
        /// Adolescência e Juventude (foco em alfabetização).
        case range10to17
        /// Vida adulta.
        case range18to59
        /// Idosos.
        case range60Plus
    }
    
    /// Tipos de vulnerabilidades educacionais mapeadas.
    public enum VulnerabilityType: String, Sendable {
        /// Pessoa em idade escolar que não frequenta a rede de ensino.
        case notInSchool
        /// Pessoa que declara não saber ler ou escrever.
        case illiteracy
    }
    
    /// Relatório consolidado de vulnerabilidades educacionais da família.
    public struct VulnerabilityReport: Sendable {
        private var counts: [String: Int] = [:]
        
        /// Incrementa o contador para uma combinação específica de vulnerabilidade e faixa etária.
        public mutating func increment(vulnerability: VulnerabilityType, ageRange: AgeRange) {
            let key = "\(vulnerability.rawValue)_\(ageRange.rawValue)"
            counts[key, default: 0] += 1
        }
        
        /// Retorna o total de pessoas identificadas em uma vulnerabilidade e faixa específica.
        public func count(vulnerability: VulnerabilityType, ageRange: AgeRange) -> Int {
            let key = "\(vulnerability.rawValue)_\(ageRange.rawValue)"
            return counts[key] ?? 0
        }
    }
    
    // MARK: - Analytics Logic

    /// Processa a lista de membros e gera um relatório de vulnerabilidades educacionais.
    ///
    /// - Parameters:
    ///   - members: Lista de modelos auxiliares contendo dados escolares.
    ///   - now: Data de referência para cálculo de idade.
    /// - Returns: Um `VulnerabilityReport` com os contadores agregados.
    public static func calculateVulnerabilities(
        for members: [EducationalMember],
        at now: TimeStamp
    ) -> VulnerabilityReport {
        var report = VulnerabilityReport()
        
        for member in members {
            let age = member.birthDate.years(at: now)
            
            // 1. Análise de Frequência Escolar (Evasão)
            if !member.attendsSchool {
                if age <= 5 { report.increment(vulnerability: .notInSchool, ageRange: .range0to5) }
                else if age <= 14 { report.increment(vulnerability: .notInSchool, ageRange: .range6to14) }
                else if age <= 17 { report.increment(vulnerability: .notInSchool, ageRange: .range15to17) }
            }
            
            // 2. Análise de Alfabetização
            if !member.canReadWrite {
                if age >= 10 && age <= 17 { report.increment(vulnerability: .illiteracy, ageRange: .range10to17) }
                else if age >= 18 && age <= 59 { report.increment(vulnerability: .illiteracy, ageRange: .range18to59) }
                else if age >= 60 { report.increment(vulnerability: .illiteracy, ageRange: .range60Plus) }
            }
        }
        
        return report
    }
}
