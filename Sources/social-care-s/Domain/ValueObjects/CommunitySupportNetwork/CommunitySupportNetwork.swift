import Foundation

/// Um Value Object que representa a rede de apoio comunitário de um paciente.
///
/// Este objeto consolida informações sobre suporte familiar, vizinhança,
/// participação em grupos e situações de vulnerabilidade social.
public struct CommunitySupportNetwork: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Constants
    
    /// Limite máximo de caracteres para o campo de conflitos familiares.
    public static let maxFamilyConflictsLength = 300

    // MARK: - Properties
    
    /// Indica se o paciente possui suporte de parentes.
    public let hasRelativeSupport: Bool
    
    /// Indica se o paciente possui suporte de vizinhos.
    public let hasNeighborSupport: Bool
    
    /// Relato textual sobre conflitos familiares.
    public let familyConflicts: String
    
    /// Indica se o paciente participa de grupos comunitários.
    public let patientParticipatesInGroups: Bool
    
    /// Indica se a família participa de grupos comunitários.
    public let familyParticipatesInGroups: Bool
    
    /// Indica se o paciente tem acesso a lazer.
    public let patientHasAccessToLeisure: Bool
    
    /// Indica se o paciente enfrenta discriminação na comunidade.
    public let facesDiscrimination: Bool

    // MARK: - Initializer

    /// Inicializa uma instância validada de `CommunitySupportNetwork`.
    ///
    /// - Throws: `CommunitySupportNetworkError` em caso de erro de validação.
    public init(
        hasRelativeSupport: Bool,
        hasNeighborSupport: Bool,
        familyConflicts: String,
        patientParticipatesInGroups: Bool,
        familyParticipatesInGroups: Bool,
        patientHasAccessToLeisure: Bool,
        facesDiscrimination: Bool
    ) throws {
        
        let trimmedConflicts = familyConflicts.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validação: Não permitir apenas espaços se a string original não for vazia
        guard familyConflicts.isEmpty || !trimmedConflicts.isEmpty else {
            throw CommunitySupportNetworkError.familyConflictsWhitespace
        }

        // Validação: Tamanho máximo (Regra de Negócio)
        guard trimmedConflicts.count <= Self.maxFamilyConflictsLength else {
            throw CommunitySupportNetworkError.familyConflictsTooLong(limit: Self.maxFamilyConflictsLength)
        }

        let normalizedConflicts = familyConflicts.isEmpty ? "" : trimmedConflicts

        self.hasRelativeSupport = hasRelativeSupport
        self.hasNeighborSupport = hasNeighborSupport
        self.familyConflicts = normalizedConflicts
        self.patientParticipatesInGroups = patientParticipatesInGroups
        self.familyParticipatesInGroups = familyParticipatesInGroups
        self.patientHasAccessToLeisure = patientHasAccessToLeisure
        self.facesDiscrimination = facesDiscrimination
    }
}
