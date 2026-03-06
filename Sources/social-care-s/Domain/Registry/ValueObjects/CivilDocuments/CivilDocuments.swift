/// Value Object que agrupa os documentos de identificação civil de um paciente.
///
/// Ao menos um dos documentos deve ser informado — um `CivilDocuments` vazio não tem valor semântico.
public struct CivilDocuments: Codable, Equatable, Hashable, Sendable {

    public let cpf: CPF?
    public let nis: NIS?
    public let rgDocument: RGDocument?

    public init(cpf: CPF?, nis: NIS?, rgDocument: RGDocument?) throws {
        guard cpf != nil || nis != nil || rgDocument != nil else {
            throw CivilDocumentsError.atLeastOneDocumentRequired
        }
        self.cpf = cpf
        self.nis = nis
        self.rgDocument = rgDocument
    }
}
