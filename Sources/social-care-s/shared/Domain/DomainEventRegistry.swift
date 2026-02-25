import Foundation

/// Um registro centralizado para decodificação de eventos de domínio heterogêneos.
public final class DomainEventRegistry: Sendable {
    public static let shared = DomainEventRegistry()
    
    // Armazena as closures de decodificação mapeadas pelo nome do tipo do evento
    private let decoders: ThreadSafeDictionary<String, @Sendable (Data) throws -> any DomainEvent>
    
    private init() {
        self.decoders = ThreadSafeDictionary()
    }
    
    /// Registra um novo tipo de evento para decodificação futura.
    public func register<T: DomainEvent & Decodable>(_ eventType: T.Type) {
        let typeName = String(describing: eventType)
        decoders.set(typeName) { @Sendable data in
            try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    /// Tenta decodificar um evento a partir do nome do tipo e do payload JSON.
    public func decode(typeName: String, data: Data) throws -> any DomainEvent {
        guard let decoder = decoders.get(typeName) else {
            throw DomainEventError.unregisteredEventType(typeName)
        }
        return try decoder(data)
    }
}

public enum DomainEventError: Error {
    case unregisteredEventType(String)
}

/// Helper simples para manter o dicionário thread-safe.
private final class ThreadSafeDictionary<K: Hashable & Sendable, V: Sendable>: @unchecked Sendable {
    private var storage: [K: V] = [:]
    private let lock = NSLock()
    
    func set(_ key: K, value: V) {
        lock.lock()
        defer { lock.unlock() }
        self.storage[key] = value
    }
    
    func get(_ key: K) -> V? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
}
