import Foundation

/// Erro genérico lançado por repositórios quando uma constraint de unicidade é violada.
/// Permite que a camada de Application mapeie para o erro específico do caso de uso
/// sem que o repositório conheça erros de negócio.
public enum PersistenceConflictError: Error, Sendable {
    case uniqueViolation(constraint: String, detail: String?)
}

/// Erro lançado por mappers quando dados persistidos estão em estado inconsistente.
/// Indica corrupção ou evolução de schema sem migração.
public enum PersistenceDataIntegrityError: Error, Sendable {
    case invalidEnumValue(column: String, value: String, expected: String)
}
