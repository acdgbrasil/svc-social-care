import Foundation

/// Port para operacoes de administracao de itens em lookup tables.
public protocol LookupRepository: Sendable {

    /// Verifica se um codigo ja existe na tabela.
    func codigoExists(in table: String, codigo: String) async throws -> Bool

    /// Verifica se um item existe na tabela.
    func itemExists(in table: String, id: UUID) async throws -> Bool

    /// Verifica se um item esta referenciado por dados de pacientes.
    func isItemReferenced(in table: String, id: UUID) async throws -> Bool

    /// Cria um novo item na tabela.
    func createItem(in table: String, id: UUID, codigo: String, descricao: String,
                    metadata: LookupItemMetadata?) async throws

    /// Atualiza a descricao de um item.
    func updateDescription(in table: String, id: UUID, descricao: String) async throws

    /// Alterna o estado ativo/inativo de um item.
    func toggleActive(in table: String, id: UUID) async throws
}
