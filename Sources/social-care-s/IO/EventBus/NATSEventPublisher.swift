import Foundation
import Synchronization
import Nats

/// Protocolo para publicação de eventos de domínio no NATS.
/// Permite injeção de dependência e teste com doubles.
public protocol NATSPublishing: Sendable {
    func publish(_ event: any DomainEvent, typeName: String) async throws
    func disconnect() async
}

/// Publicador de eventos de domínio via NATS Core.
///
/// Publica em subjects no padrão `social-care.events.<EventTypeName>`.
/// O JetStream stream `SOCIAL_CARE_EVENTS` (configurado no servidor com
/// subject filter `social-care.events.>`) captura automaticamente as mensagens.
public actor NATSEventPublisher: NATSPublishing {
    private let url: URL
    private nonisolated(unsafe) var client: NatsClient?
    private let encoder: JSONEncoder

    public init(url: String = "nats://nats:4222") {
        self.url = URL(string: url) ?? URL(string: "nats://nats:4222")!
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
    }

    /// Conecta ao servidor NATS. Chamado lazily na primeira publicação.
    private func ensureConnected() async throws {
        guard client == nil else { return }
        let nats = NatsClientOptions()
            .url(url)
            .build()
        try await nats.connect()
        self.client = nats
    }

    /// Publica um evento de domínio no subject `social-care.events.<typeName>`.
    public func publish(_ event: any DomainEvent, typeName: String) async throws {
        try await ensureConnected()

        guard let client else { return }

        let subject = "social-care.events.\(typeName)"

        // Codifica o evento como JSON usando o tipo concreto via existential
        let data: Data
        if let encodable = event as? any (DomainEvent & Encodable) {
            data = try encoder.encode(AnyEncodableEvent(wrapped: encodable))
        } else {
            // Fallback: serializa apenas id + occurredAt
            let fallback: [String: String] = [
                "id": event.id.uuidString,
                "occurredAt": ISO8601DateFormatter().string(from: event.occurredAt)
            ]
            data = try JSONSerialization.data(withJSONObject: fallback)
        }

        try await client.publish(data, subject: subject)
    }

    public func disconnect() async {
        let nats = client
        client = nil
        try? await nats?.close()
    }
}

/// Wrapper para codificar eventos via existential opening.
private struct AnyEncodableEvent: Encodable {
    let wrapped: any (DomainEvent & Encodable)

    func encode(to encoder: Encoder) throws {
        try wrapped.encode(to: encoder)
    }
}
