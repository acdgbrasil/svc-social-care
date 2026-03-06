import Foundation

/// Value Object que representa o resumo consolidado de saúde social de um paciente.
///
/// Este objeto captura indicadores rápidos de vulnerabilidade biopsicossocial,
/// como necessidade de cuidados constantes e deficiências de mobilidade.
public struct SocialHealthSummary: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Indica se o paciente requer cuidados de terceiros de forma ininterrupta.
    public let requiresConstantCare: Bool
    
    /// Indica se o paciente possui limitações severas de locomoção.
    public let hasMobilityImpairment: Bool
    
    /// Lista de apoios ou equipamentos dos quais o paciente depende (ex: cadeira de rodas, oxigênio).
    /// - Note: Normalizada para evitar duplicatas e espaços em branco.
    public let functionalDependencies: [String]
    
    /// Indica se o paciente depende de medicamentos de uso contínuo ou alto custo.
    public let hasRelevantDrugTherapy: Bool

    // MARK: - Initializer

    /// Inicializa um resumo de saúde validado.
    ///
    /// - Throws: `SocialHealthSummaryError.functionalDependenciesEmpty` se algum item da lista estiver vazio.
    public init(
        requiresConstantCare: Bool,
        hasMobilityImpairment: Bool,
        functionalDependencies: [String],
        hasRelevantDrugTherapy: Bool
    ) throws {
        let normalized = Self.normalize(dependencies: functionalDependencies)
        
        guard !normalized.hasEmpty else {
            throw SocialHealthSummaryError.functionalDependenciesEmpty
        }

        self.requiresConstantCare = requiresConstantCare
        self.hasMobilityImpairment = hasMobilityImpairment
        self.functionalDependencies = normalized.unique
        self.hasRelevantDrugTherapy = hasRelevantDrugTherapy
    }

    // MARK: - Private Logic

    /// Normaliza a lista de dependências aplicando trim e removendo duplicatas.
    private static func normalize(dependencies: [String]) -> (hasEmpty: Bool, unique: [String]) {
        let trimmed = dependencies.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let hasEmpty = trimmed.contains { $0.isEmpty }
        
        if hasEmpty {
            return (hasEmpty: true, unique: [])
        }
        
        var uniqueItems = [String]()
        var seen = Set<String>()
        for item in trimmed {
            if !seen.contains(item) {
                uniqueItems.append(item)
                seen.insert(item)
            }
        }
        
        return (hasEmpty: false, unique: uniqueItems)
    }
}
