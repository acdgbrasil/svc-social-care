import Foundation

/// Um Value Object que representa o resumo de saúde social de um paciente.
///
/// Consolida informações sobre necessidade de cuidados constantes, mobilidade,
/// dependências funcionais e terapias medicamentosas relevantes.
public struct SocialHealthSummary: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// Indica se o paciente requer cuidados constantes.
    public let requiresConstantCare: Bool
    
    /// Indica se o paciente possui deficiência de mobilidade.
    public let hasMobilityImpairment: Bool
    
    /// Lista de dependências funcionais normalizada e sem duplicatas.
    public let functionalDependencies: [String]
    
    /// Indica se o paciente faz uso de terapia medicamentosa relevante.
    public let hasRelevantDrugTherapy: Bool

    // MARK: - Initializer

    /// Inicializa uma instância validada de `SocialHealthSummary`.
    ///
    /// - Throws: `SocialHealthSummaryError` em caso de erro de validação.
    public init(
        requiresConstantCare: Bool,
        hasMobilityImpairment: Bool,
        functionalDependencies: [String],
        hasRelevantDrugTherapy: Bool
    ) throws {
        
        let normalized = Self.normalize(functionalDependencies)
        
        guard !normalized.hasEmpty else {
            throw SocialHealthSummaryError.functionalDependenciesEmpty
        }

        self.requiresConstantCare = requiresConstantCare
        self.hasMobilityImpairment = hasMobilityImpairment
        self.functionalDependencies = normalized.unique
        self.hasRelevantDrugTherapy = hasRelevantDrugTherapy
    }

    // MARK: - Private Helpers

    /// Normaliza a lista de dependências aplicando trim, verificando vazios e removendo duplicatas.
    private static func normalize(_ dependencies: [String]) -> (hasEmpty: Bool, unique: [String]) {
        let trimmed = dependencies.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let hasEmpty = trimmed.contains { $0.isEmpty }
        
        if hasEmpty {
            return (hasEmpty: true, unique: [])
        }
        
        // Mantém a ordem original enquanto remove duplicatas
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
