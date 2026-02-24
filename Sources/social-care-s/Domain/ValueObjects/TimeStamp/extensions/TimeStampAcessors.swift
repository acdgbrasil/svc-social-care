import Foundation

extension TimeStamp {

    // MARK: - Accessors (Deterministic UTC)

    /// O ano da data em UTC.
    public var year: Int {
        return Self.utcCalendar.component(.year, from: self.date)
    }
    
    /// O mês da data em UTC (1-12).
    public var month: Int {
        return Self.utcCalendar.component(.month, from: self.date)
    }

    /// O dia do mês em UTC.
    public var day: Int {
        return Self.utcCalendar.component(.day, from: self.date)
    }

    /// A hora do dia em UTC (0-23).
    public var hour: Int {
        return Self.utcCalendar.component(.hour, from: self.date)
    }

    /// O minuto em UTC.
    public var minute: Int {
        return Self.utcCalendar.component(.minute, from: self.date)
    }

    /// O segundo em UTC.
    public var seconds: Int {
        return Self.utcCalendar.component(.second, from: self.date)
    }
}