import Foundation
import SQLKit
import Logging

/// Um Actor que gerencia a leitura e distribuição de eventos do Outbox.
/// Garante que apenas um processo de polling ocorra por vez e distribui
/// os eventos via AsyncStream para processamento paralelo.
public actor SQLKitOutboxRelay: Sendable {
    private let db: any SQLDatabase
    private var isPolling = false
    private let pollInterval: Duration
    private let natsPublisher: (any NATSPublishing)?
    private let logger: Logger

    // Armazena as continuações dos streams ativos
    private var continuations: [UUID: AsyncStream<any DomainEvent>.Continuation] = [:]

    public init(db: any SQLDatabase, natsPublisher: (any NATSPublishing)? = nil, pollInterval: Duration = .seconds(1)) {
        self.db = db
        self.natsPublisher = natsPublisher
        self.pollInterval = pollInterval
        self.logger = Logger(label: "outbox-relay")
    }
    
    /// Cria um novo stream de eventos do Outbox.
    /// Múltiplos consumidores podem chamar este método para receber eventos.
    public func events() -> AsyncStream<any DomainEvent> {
        let streamId = UUID()
        return AsyncStream { continuation in
            continuation.onTermination = { @Sendable _ in
                Task { [streamId, weak relay = self] in
                    await relay?.removeContinuation(id: streamId)
                }
            }
            
            // Usamos um Task para interagir com o estado do actor
            Task { [streamId, weak relay = self] in
                await relay?.addContinuation(continuation, withId: streamId)
            }
        }
    }
    
    private func addContinuation(_ continuation: AsyncStream<any DomainEvent>.Continuation, withId id: UUID) {
        self.continuations[id] = continuation
        if !isPolling {
            Task { await self.startPolling() }
        }
    }
    
    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    /// Inicia o polling em modo standalone (sem consumers in-process).
    /// Usado quando o relay tem um NATSPublisher configurado e precisa
    /// rodar continuamente independente de ter consumers via `events()`.
    public func startContinuousPolling() async {
        guard !isPolling else { return }
        isPolling = true

        while !Task.isCancelled {
            do {
                try await pollAndDistribute()
            } catch {
                logger.error("Outbox relay poll failed", metadata: ["error": "\(error)"])
            }

            try? await Task.sleep(for: pollInterval)
        }

        isPolling = false
    }

    private func startPolling() async {
        guard !isPolling else { return }
        isPolling = true

        while !continuations.isEmpty {
            do {
                try await pollAndDistribute()
            } catch {
                logger.error("Outbox relay poll failed", metadata: ["error": "\(error)"])
            }

            try? await Task.sleep(for: pollInterval)
        }

        isPolling = false
    }
    
    private func pollAndDistribute() async throws {
        // 1. Busca mensagens não processadas
        let messages = try await db.select()
            .column("*")
            .from("outbox_messages")
            .where("processed_at", .is, SQLLiteral.null)
            .orderBy("occurred_at", .ascending)
            .limit(50)
            .all(decoding: OutboxMessageModel.self)

        guard !messages.isEmpty else { return }

        var processedIds: [UUID] = []
        var auditEntries: [AuditTrailModel] = []
        let now = Date()

        for message in messages {
            // 2. Tenta decodificar o evento
            do {
                let event = try await DomainEventRegistry.shared.decode(
                    typeName: message.event_type,
                    data: Data(message.payload.utf8)
                )

                // 3. Publica no NATS (at-least-once: se falhar, não marca como processed)
                if let nats = natsPublisher {
                    try await nats.publish(event, typeName: message.event_type)
                }

                // 4. Distribui para todos os streams ativos (in-process)
                for continuation in continuations.values {
                    continuation.yield(event)
                }

                // 5. Prepara entrada no audit trail
                let parsed = Self.extractFields(from: message.payload)
                let aggregateId = parsed.aggregateId ?? message.id
                auditEntries.append(AuditTrailModel(
                    id: message.id,
                    aggregate_type: "Patient",
                    aggregate_id: aggregateId,
                    event_type: message.event_type,
                    actor_id: parsed.actorId,
                    payload: message.payload,
                    occurred_at: message.occurred_at,
                    recorded_at: now
                ))

                processedIds.append(message.id)
            } catch {
                logger.warning("Failed to process outbox event", metadata: [
                    "eventId": "\(message.id)",
                    "eventType": .string(message.event_type),
                    "error": "\(error)"
                ])
                // Só marca como processed se foi erro de decode (não de NATS)
                if (error as? DomainEventError) != nil {
                    processedIds.append(message.id)
                }
                // Se NATS falhou: não adiciona ao processedIds → retry na próxima poll
            }
        }

        // 5. Persiste audit trail e marca outbox como processado
        if !processedIds.isEmpty {
            let finalAudit = auditEntries
            let finalIds = processedIds
            try await db.transaction { tx in
                for entry in finalAudit {
                    try await tx.insert(into: "audit_trail").model(entry).run()
                }
                try await tx.update("outbox_messages")
                    .set("processed_at", to: now)
                    .where("id", .in, finalIds)
                    .run()
            }
        }
    }

    private static func extractFields(from payload: String) -> (aggregateId: UUID?, actorId: String?) {
        guard let json = try? JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any] else {
            return (nil, nil)
        }
        let aggregateId = (json["patientId"] as? String).flatMap { UUID(uuidString: $0) }
        let actorId = json["actorId"] as? String
        return (aggregateId, actorId)
    }
}
