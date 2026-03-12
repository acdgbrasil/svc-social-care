import Foundation
import SQLKit

/// Um Actor que gerencia a leitura e distribuição de eventos do Outbox.
/// Garante que apenas um processo de polling ocorra por vez e distribui
/// os eventos via AsyncStream para processamento paralelo.
public actor SQLKitOutboxRelay: Sendable {
    private let db: any SQLDatabase
    private var isPolling = false
    private let pollInterval: Duration
    
    // Armazena as continuações dos streams ativos
    private var continuations: [UUID: AsyncStream<any DomainEvent>.Continuation] = [:]
    
    public init(db: any SQLDatabase, pollInterval: Duration = .seconds(1)) {
        self.db = db
        self.pollInterval = pollInterval
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
    
    private func startPolling() async {
        guard !isPolling else { return }
        isPolling = true
        
        while !continuations.isEmpty {
            do {
                try await pollAndDistribute()
            } catch {
                print("❌ Outbox Relay Error: \(error.localizedDescription)")
            }
            
            try? await Task.sleep(for: pollInterval)
        }
        
        isPolling = false
    }
    
    private func pollAndDistribute() async throws {
        // 1. Busca mensagens não processadas
        let messages = try await db.select()
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

                // 3. Distribui para todos os streams ativos
                for continuation in continuations.values {
                    continuation.yield(event)
                }

                // 4. Prepara entrada no audit trail
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
                print("⚠️ Failed to decode outbox event \(message.id): \(error)")
                processedIds.append(message.id)
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
