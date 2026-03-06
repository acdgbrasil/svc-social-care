import Foundation

public struct RGDocument: Codable, Equatable, Hashable, Sendable {
    public let number: String; public let issuingState: String; public let issuingAgency: String; public let issueDate: TimeStamp
    public init(number: String, issuingState: String, issuingAgency: String, issueDate: TimeStamp, now: TimeStamp = .now) throws {
        let normalized = number.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { throw RGDocumentError.emptyNumber }
        let compact = normalized.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard compact.range(of: "^[0-9]{8}[0-9X]$", options: .regularExpression) != nil else { throw RGDocumentError.invalidNumberFormat(value: normalized) }
        guard Self.hasValidCheckDigit(compact) else {
            let expected = Self.expectedCheckDigit(for: String(compact.prefix(8)))
            let provided = String(compact.suffix(1))
            throw RGDocumentError.invalidCheckDigit(value: compact, expected: expected, provided: provided)
        }
        let state = issuingState.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Self.validStates.contains(state) else { throw RGDocumentError.invalidIssuingState(value: state) }
        let agency = issuingAgency.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).uppercased()
        guard !agency.isEmpty else { throw RGDocumentError.emptyIssuingAgency }
        guard issueDate.date <= now.date else { throw RGDocumentError.issueDateInFuture(date: issueDate.toISOString(), now: now.toISOString()) }
        self.number = compact; self.issuingState = state; self.issuingAgency = agency; self.issueDate = issueDate
    }
    public var formattedNumber: String { "\(number.prefix(8))-\(number.suffix(1))" }
    private static let validStates: Set<String> = ["AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"]
    private static func hasValidCheckDigit(_ c: String) -> Bool { expectedCheckDigit(for: String(c.prefix(8))) == String(c.suffix(1)) }
    private static func expectedCheckDigit(for b: String) -> String {
        let d = b.compactMap { Int(String($0)) }
        let sum = zip(d, [2, 3, 4, 5, 6, 7, 8, 9]).map { $0 * $1 }.reduce(0, +)
        let r = sum % 11; let res = 11 - r
        if res == 10 { return "X" }
        if res == 11 { return "0" }
        return String(res)
    }
}
