import Foundation

/// Um registro centralizado para decodificação de eventos de domínio heterogêneos.
/// Utiliza o padrão de Actor para garantir thread-safety idiomático no Swift.
public actor DomainEventRegistry: Sendable {
    public static let shared = DomainEventRegistry()
    
    // Armazena as closures de decodificação mapeadas pelo nome do tipo do evento
    private var decoders: [String: @Sendable (Data) throws -> any DomainEvent] = [:]
    
    private init() {}
    
    /// Registra um novo tipo de evento para decodificação futura.
    public func register<T: DomainEvent & Decodable>(_ eventType: T.Type) {
        let typeName = String(describing: eventType)
        decoders[typeName] = { @Sendable data in
            try JSONDecoder().decode(T.self, from: data)
        }
    }
    
    /// Tenta decodificar um evento a partir do nome do tipo e do payload JSON.
    public func decode(typeName: String, data: Data) throws -> any DomainEvent {
        guard let decoder = decoders[typeName] else {
            throw DomainEventError.unregisteredEventType(typeName)
        }
        return try decoder(data)
    }
}

public enum DomainEventError: Error {
    case unregisteredEventType(String)
}
