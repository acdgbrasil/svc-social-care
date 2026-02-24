import Foundation

/// Um Value Object que representa um ponto específico no tempo (Timestamp).
///
/// Encapsula um objeto `Date` e fornece uma API funcional para manipulação
/// e acesso determinístico a componentes de data em UTC.
public struct TimeStamp: Codable, Equatable, Hashable, Sendable {
    /// O objeto `Date` subjacente.
    public let date: Date

    /// Retorna o timestamp do instante atual.
    public static var now: TimeStamp {
        return try! TimeStamp(Date())
    }

    /// Inicializa um `TimeStamp` a partir de um objeto `Date`.
    ///
    /// - Parameter date: A data bruta.
    /// - Throws: `TimeStampError.invalidDate` se a data for nula.
    public init(_ date: Date?) throws {
        guard let date = date else {
            throw TimeStampError.invalidDate("nil")
        }
        self.date = date
    }

    /// Inicializa um `TimeStamp` a partir de uma string ISO8601.
    ///
    /// - Parameter iso: A string no formato ISO (ex: "2024-01-01T12:00:00Z").
    /// - Throws: `TimeStampError.invalidDate` se a string for inválida.
    public init(iso: String) throws {
        let date = try? Date(iso, strategy: .iso8601)
        
        guard let validDate = date else {
            throw TimeStampError.invalidDate(iso)
        }
        self.date = validDate
    }
}
