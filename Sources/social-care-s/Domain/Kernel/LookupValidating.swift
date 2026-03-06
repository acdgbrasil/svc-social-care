import Foundation

/// Protocolo que define o contrato para validação de IDs de lookup contra tabelas de domínio.
///
/// Implementações deste protocolo devem consultar as tabelas de metadados (dominio_*)
/// para verificar se um determinado ID existe e é válido.
public protocol LookupValidating: Sendable {
    /// Verifica se um ID de lookup existe em uma tabela de domínio específica.
    ///
    /// - Parameters:
    ///   - id: O identificador de lookup a ser validado.
    ///   - table: O nome da tabela de domínio (ex: "dominio_parentesco").
    /// - Returns: `true` se o ID existe na tabela, `false` caso contrário.
    /// - Throws: Erros de infraestrutura (conexão, consulta SQL, etc).
    func exists(id: LookupId, in table: String) async throws -> Bool
}
