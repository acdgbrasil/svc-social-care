import Foundation

public enum WithdrawReason: String, Sendable, Codable, Equatable, CaseIterable {
    case patientDeclined
    case noResponse
    case duplicateRecord
    case ineligible
    case transferredBeforeAdmit
    case other
}
