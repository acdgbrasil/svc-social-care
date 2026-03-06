import Foundation

extension TimeStamp {
    /// Calcula a idade em anos completos a partir desta data até uma data de referência.
    ///
    /// - Parameter referenceDate: A data de referência para o cálculo (padrão: agora).
    /// - Returns: A idade em anos completos.
    public func years(at referenceDate: TimeStamp = .now) -> Int {
        let calendar = Self.utcCalendar
        let components = calendar.dateComponents([.year], from: self.date, to: referenceDate.date)
        return components.year ?? 0
    }
}
