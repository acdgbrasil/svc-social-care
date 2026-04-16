import Foundation

public struct RGDocument: Codable, Equatable, Hashable, Sendable {
    public let number: String; public let issuingState: String; public let issuingAgency: String; public let issueDate: TimeStamp
    public init(number: String, issuingState: String, issuingAgency: String, issueDate: TimeStamp, now: TimeStamp = .now) throws {
        let normalized = number.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else { throw RGDocumentError.emptyNumber }
        let compact = normalized.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard compact.range(of: "^[A-Z0-9]{4,15}$", options: .regularExpression) != nil else { throw RGDocumentError.invalidNumberFormat(value: compact) }
        let state = issuingState.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Self.validStates.contains(state) else { throw RGDocumentError.invalidIssuingState(value: state) }
        let agency = issuingAgency.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).uppercased()
        guard !agency.isEmpty else { throw RGDocumentError.emptyIssuingAgency }
        guard issueDate.date <= now.date else { throw RGDocumentError.issueDateInFuture(date: issueDate.toISOString(), now: now.toISOString()) }
        self.number = compact; self.issuingState = state; self.issuingAgency = agency; self.issueDate = issueDate
    }
    private static let validStates: Set<String> = ["AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"]
}
