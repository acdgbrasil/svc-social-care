import Foundation

/// Implementação concreta do EventBus baseada no padrão Transactional Outbox.
///
/// Os eventos já são persistidos na tabela `outbox_messages` pelo `PatientRepository.save()`,
/// dentro da mesma transação que o agregado. Este actor registra a intenção de publicação
/// e o `SQLKitOutboxRelay` distribui via polling.
public actor OutboxEventBus: EventBus {
    public init() {}

    /// Recebe os eventos já persistidos no Outbox e os sinaliza para processamento.
    /// O `SQLKitOutboxRelay` será responsável pela distribuição real via polling.
    public func publish(_ events: [any DomainEvent]) async throws {
        // Os eventos já foram escritos na tabela outbox_messages pelo repository.save().
        // Aqui poderíamos sinalizar o relay para uma poll imediata —
        // por ora, o relay processa automaticamente via polling periódico.
        guard !events.isEmpty else { return }
    }
}
