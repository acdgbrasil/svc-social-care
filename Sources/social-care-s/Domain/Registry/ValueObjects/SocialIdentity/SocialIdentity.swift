import Foundation

/// Value Object que representa a identidade étnica e social de uma família no contexto do SUAS.
///
/// Refatorado para Versão 2.0 (Metadata-Driven) utilizando identificadores de lookup.
public struct SocialIdentity: Codable, Equatable, Hashable, Sendable {

    /// O identificador do tipo de identidade social (FK para dominio_tipo_identidade).
    public let typeId: LookupId
    
    /// Descrição detalhada ou complementar (obrigatória para tipos específicos como 'OUTRAS').
    public let otherDescription: String?

    /// Inicializa uma instância validada de `SocialIdentity`.
    ///
    /// - Parameters:
    ///   - typeId: O ID do tipo de identidade.
    ///   - otherDescription: Texto descritivo opcional.
    ///   - isOtherType: Flag auxiliar (geralmente vinda do UseCase/Lookup) para validar obrigatoriedade.
    /// - Throws: `SocialIdentityError.descriptionRequiredForOtherType` se a descrição for necessária e estiver vazia.
    public init(
        typeId: LookupId,
        otherDescription: String?,
        isOtherType: Bool = false
    ) throws {
        let trimmedDescription = otherDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = (trimmedDescription?.isEmpty ?? true) ? nil : trimmedDescription

        if isOtherType && finalDescription == nil {
            throw SocialIdentityError.descriptionRequiredForOtherType
        }

        self.typeId = typeId
        self.otherDescription = finalDescription
    }
}
