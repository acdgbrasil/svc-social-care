import Foundation

extension TimeStamp: Comparable {
    // MARK: - Comparable & Equatable
    
    /// Compara se um timestamp ocorre cronologicamente antes de outro.
    public static func < (lhs: TimeStamp, rhs: TimeStamp) -> Bool { 
        return lhs.date < rhs.date 
    }

    /// Verifica a igualdade cronológica entre dois timestamps.
    public static func == (lhs: TimeStamp, rhs: TimeStamp) -> Bool { 
        return lhs.date == rhs.date 
    }

    // MARK: - Utility Methods
    
    /// Verifica se este timestamp ocorre no mesmo dia civil que outro (em UTC).
    ///
    /// - Parameter other: O outro timestamp para comparação.
    /// - Returns: `true` se as datas (dia/mês/ano) forem as mesmas em UTC.
    public func isSameDay(as other: TimeStamp) -> Bool { 
        return Self.utcCalendar.isDate(self.date, inSameDayAs: other.date) 
    }
    
    /// Converte o timestamp para uma string formatada em ISO8601 com frações de segundo.
    ///
    /// - Returns: String no formato "yyyy-MM-dd'T'HH:mm:ss.SSSZ".
    public func toISOString() -> String {
        return self.date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
}
