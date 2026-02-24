import Foundation

/// Protocolo que todo evento de domínio deve assinar.
public protocol DomainEvent: Sendable {
    var id: UUID { get }
    var occurredAt: Date { get }
}

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
