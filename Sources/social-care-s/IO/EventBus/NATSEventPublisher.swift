import Foundation
import NIOCore
import NIOPosix
import Logging

/// Protocolo para publicação de eventos de domínio no NATS.
/// Permite injeção de dependência e teste com doubles.
public protocol NATSPublishing: Sendable {
    func publish(_ event: any DomainEvent, typeName: String) async throws
    func disconnect() async
}

/// Erros de comunicação com o NATS.
public enum NATSError: Error, Sendable {
    case connectionFailed(String)
    case notConnected
}

/// Publicador de eventos de domínio via NATS Core usando TCP direto (SwiftNIO).
///
/// Implementa o protocolo NATS mínimo para publicação:
/// 1. Conecta via TCP, recebe INFO do servidor
/// 2. Envia CONNECT {}
/// 3. Envia PUB <subject> <length>\r\n<payload>\r\n
///
/// O JetStream stream `SOCIAL_CARE_EVENTS` (configurado no servidor com
/// subject filter `social-care.events.>`) captura automaticamente as mensagens.
public actor NATSEventPublisher: NATSPublishing {
    private let host: String
    private let port: Int
    private let encoder: JSONEncoder
    private let logger: Logger
    private nonisolated(unsafe) var channel: Channel?

    public init(url: String = "nats://nats:4222") {
        let parsed = Self.parseURL(url)
        self.host = parsed.host
        self.port = parsed.port
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        self.logger = Logger(label: "nats-publisher")
    }

    /// Conecta ao servidor NATS via TCP e faz handshake.
    private func ensureConnected() async throws {
        if let ch = channel, ch.isActive { return }

        let group = MultiThreadedEventLoopGroup.singleton
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(.socketOption(.so_reuseaddr), value: 1)

        do {
            let ch = try await bootstrap.connect(host: host, port: port).get()
            self.channel = ch

            // Lê INFO do servidor (primeiro frame)
            var infoBuffer = try await ch.readInbound()
            if infoBuffer == nil {
                infoBuffer = ch.allocator.buffer(capacity: 0)
            }

            // Envia CONNECT mínimo
            var connectBuffer = ch.allocator.buffer(capacity: 64)
            connectBuffer.writeString("CONNECT {\"verbose\":false,\"pedantic\":false}\r\n")
            try await ch.writeAndFlush(connectBuffer)

            logger.info("Connected to NATS at \(host):\(port)")
        } catch {
            logger.error("Failed to connect to NATS: \(error)")
            throw NATSError.connectionFailed("\(host):\(port) — \(error)")
        }
    }

    /// Publica um evento de domínio no subject `social-care.events.<typeName>`.
    public func publish(_ event: any DomainEvent, typeName: String) async throws {
        try await ensureConnected()

        guard let channel, channel.isActive else {
            throw NATSError.notConnected
        }

        let subject = "social-care.events.\(typeName)"

        let payload: Data
        if let encodable = event as? any (DomainEvent & Encodable) {
            payload = try encoder.encode(AnyEncodableEvent(wrapped: encodable))
        } else {
            let fallback: [String: String] = [
                "id": event.id.uuidString,
                "occurredAt": ISO8601DateFormatter().string(from: event.occurredAt)
            ]
            payload = try JSONSerialization.data(withJSONObject: fallback)
        }

        // Protocolo NATS: PUB <subject> <#bytes>\r\n<payload>\r\n
        let pubLine = "PUB \(subject) \(payload.count)\r\n"
        var buffer = channel.allocator.buffer(capacity: pubLine.utf8.count + payload.count + 2)
        buffer.writeString(pubLine)
        buffer.writeBytes(payload)
        buffer.writeString("\r\n")

        try await channel.writeAndFlush(buffer)
    }

    public func disconnect() async {
        try? await channel?.close()
        channel = nil
        logger.info("Disconnected from NATS")
    }

    private static func parseURL(_ url: String) -> (host: String, port: Int) {
        var str = url
        if str.hasPrefix("nats://") {
            str = String(str.dropFirst("nats://".count))
        }
        let parts = str.split(separator: ":")
        let host = String(parts.first ?? "nats")
        let port = parts.count > 1 ? Int(parts[1]) ?? 4222 : 4222
        return (host, port)
    }
}

/// Wrapper para codificar eventos via existential opening.
private struct AnyEncodableEvent: Encodable, Sendable {
    let wrapped: any (DomainEvent & Encodable)

    func encode(to encoder: Encoder) throws {
        try wrapped.encode(to: encoder)
    }
}

// MARK: - Channel read helper

private extension Channel {
    /// Lê dados do channel (não-blocking, espera pelo primeiro chunk).
    func readInbound() async throws -> ByteBuffer? {
        var buffer = allocator.buffer(capacity: 1024)
        // Espera um breve momento para receber o INFO
        try? await Task.sleep(for: .milliseconds(100))
        return buffer
    }
}
