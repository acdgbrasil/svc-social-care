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
            .limit(100)
            .all(decoding: OutboxMessageModel.self)
        
        guard !messages.isEmpty else { return }
        
        for message in messages {
            // 2. Tenta decodificar o evento
            do {
                let event = try DomainEventRegistry.shared.decode(
                    typeName: message.event_type,
                    data: message.payload
                )
                
                // 3. Distribui para todos os streams ativos
                for continuation in continuations.values {
                    continuation.yield(event)
                }
                
                // 4. Marca como processado no banco
                try await db.update("outbox_messages")
                    .set("processed_at", to: Date())
                    .where("id", .equal, message.id)
                    .run()
            } catch {
                // Se falhar a decodificação, logamos e pulamos para não travar o relay
                print("⚠️ Failed to decode outbox event \(message.id): \(error)")
            }
        }
    }
}
