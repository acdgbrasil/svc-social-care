import Foundation

/// Value Object que representa a rede de apoio comunitário e social de uma família.
///
/// Este objeto mapeia os vínculos de solidariedade (parentes, vizinhos) e a participação
/// em espaços coletivos, identificando também situações de isolamento ou discriminação.
public struct CommunitySupportNetwork: Codable, Equatable, Hashable, Sendable {
    
    // MARK: - Constants
    
    /// Limite técnico para o relato de conflitos (regra de negócio SUAS).
    public static let maxFamilyConflictsLength = 300

    // MARK: - Properties
    
    /// Indica se há suporte afetivo ou material por parte de parentes fora do núcleo residencial.
    public let hasRelativeSupport: Bool
    
    /// Indica se há suporte de vizinhos ou membros da comunidade imediata.
    public let hasNeighborSupport: Bool
    
    /// Relato descritivo sobre a natureza dos conflitos familiares, se houver.
    public let familyConflicts: String
    
    /// Indica se o titular do prontuário participa de grupos (religiosos, esportivos, etc).
    public let patientParticipatesInGroups: Bool
    
    /// Indica se outros membros da família possuem vida comunitária ativa.
    public let familyParticipatesInGroups: Bool
    
    /// Indica se a família possui acesso regular a espaços de lazer e cultura.
    public let patientHasAccessToLeisure: Bool
    
    /// Indica se a família relata sofrer estigma ou preconceito na comunidade.
    public let facesDiscrimination: Bool

    // MARK: - Initializer

    /// Inicializa uma rede de apoio validada.
    ///
    /// - Throws: `CommunitySupportNetworkError` se o relato exceder o limite ou for inconsistente.
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

        guard familyConflicts.isEmpty || !trimmedConflicts.isEmpty else {
            throw CommunitySupportNetworkError.familyConflictsWhitespace
        }

        guard trimmedConflicts.count <= Self.maxFamilyConflictsLength else {
            throw CommunitySupportNetworkError.familyConflictsTooLong(limit: Self.maxFamilyConflictsLength)
        }

        self.hasRelativeSupport = hasRelativeSupport
        self.hasNeighborSupport = hasNeighborSupport
        self.familyConflicts = familyConflicts.isEmpty ? "" : trimmedConflicts
        self.patientParticipatesInGroups = patientParticipatesInGroups
        self.familyParticipatesInGroups = familyParticipatesInGroups
        self.patientHasAccessToLeisure = patientHasAccessToLeisure
        self.facesDiscrimination = facesDiscrimination
    }
}
