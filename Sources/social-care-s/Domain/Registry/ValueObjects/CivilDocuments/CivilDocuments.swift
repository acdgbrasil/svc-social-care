/// Value Object que agrupa os documentos de identificação civil de um paciente.
///
/// Ao menos um dos documentos deve ser informado — um `CivilDocuments` vazio não tem valor semântico.
/// Quando CPF e CNS são informados simultaneamente, o CPF do CNS deve ser igual ao CPF avulso.
public struct CivilDocuments: Codable, Equatable, Hashable, Sendable {

    public let cpf: CPF?
    public let nis: NIS?
    public let rgDocument: RGDocument?
    public let cns: CNS?

    public init(cpf: CPF?, nis: NIS?, rgDocument: RGDocument?, cns: CNS? = nil) throws {
        guard cpf != nil || nis != nil || rgDocument != nil || cns != nil else {
            throw CivilDocumentsError.atLeastOneDocumentRequired
        }

        if let cpf, let cns, cpf != cns.cpf {
            throw CivilDocumentsError.cpfMismatchWithCNS
        }

        self.cpf = cpf
        self.nis = nis
        self.rgDocument = rgDocument
        self.cns = cns
    }
}
