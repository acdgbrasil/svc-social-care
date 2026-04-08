import Foundation

/// Erro genérico lançado por repositórios quando uma constraint de unicidade é violada.
/// Permite que a camada de Application mapeie para o erro específico do caso de uso
/// sem que o repositório conheça erros de negócio.
public enum PersistenceConflictError: Error, Sendable {
    case uniqueViolation(constraint: String, detail: String?)
}
