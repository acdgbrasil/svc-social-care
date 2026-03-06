import Foundation

// MARK: - Core Domain Events

/// Protocolo que todo evento de domínio deve assinar. Representa um fato ocorrido no passado.
public protocol DomainEvent: Sendable {
    var id: UUID { get }
    var occurredAt: Date { get }
}

/// Barramento de eventos para propagação de mudanças de estado.
public protocol EventBus: Sendable {
    /// Publica uma coleção de eventos de forma assíncrona.
    func publish(_ events: [any DomainEvent]) async throws
}

// MARK: - CQRS: Commands

/// Marca uma intenção de mudança de estado. Deve ser uma struct imutável.
public protocol Command: Sendable {}

/// Marca um comando que produz um resultado simples (ex: UUID do recurso criado).
public protocol ResultCommand: Command {
    associatedtype Result: Sendable
}

/// Handler para processamento de comandos. Sempre um Actor para garantir exclusão mútua.
public protocol CommandHandling<C>: Actor {
    associatedtype C: Command
    /// Processa o comando. Falhas devem ser comunicadas via throws.
    func handle(_ command: C) async throws
}

/// Handler para comandos que retornam um resultado.
public protocol ResultCommandHandling<C>: Actor {
    associatedtype C: ResultCommand
    /// Processa o comando e retorna o resultado.
    func handle(_ command: C) async throws -> C.Result
}

// MARK: - CQRS: Queries

/// Marca uma intenção de leitura de dados. Não deve ter efeitos colaterais.
public protocol Query: Sendable {
    associatedtype Result: Sendable
}

/// Handler para execução de consultas. Geralmente uma struct pura (sem estado mutável).
public protocol QueryHandling<Q>: Sendable {
    associatedtype Q: Query
    /// Executa a consulta e retorna o resultado otimizado para leitura.
    func handle(_ query: Q) async throws -> Q.Result
}

// MARK: - Domain Aggregates

/// Define as capacidades de um Agregado que utiliza Event Sourcing/Outbox Pattern.
public protocol EventSourcedAggregate: Sendable {
    associatedtype ID: Sendable & Equatable
    
    var id: ID { get }
    var version: Int { get }
    var uncommittedEvents: [any DomainEvent] { get }
}

// MARK: - Default Implementation (PoP)
extension EventSourcedAggregate {
    
    /// Registra um novo evento e incrementa a versão.
    public mutating func recordEvent(_ event: any DomainEvent) {
        if var internalSelf = self as? any EventSourcedAggregateInternal {
            internalSelf.addEvent(event)
            // Re-atribuição para garantir que a cópia mutada seja aplicada de volta à struct
            if let back = internalSelf as? Self {
                self = back
            }
        }
    }
}

/// Protocolo interno para permitir mutação controlada via PoP.
public protocol EventSourcedAggregateInternal {
    mutating func addEvent(_ event: any DomainEvent)
}
