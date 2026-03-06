import Foundation

public struct CEP: Codable, Equatable, Hashable, Sendable {
    public enum PostalRegion: Int, Codable, Equatable, Hashable, Sendable {
        case region0 = 0, region1, region2, region3, region4, region5, region6, region7, region8, region9
    }
    public enum DistributionKind: String, Codable, Equatable, Hashable, Sendable {
        case streetRange = "STREET_RANGE", specialCodes = "SPECIAL_CODES", promotional = "PROMOTIONAL", postOfficeUnits = "POST_OFFICE_UNITS", other = "OTHER"
    }
    public let value: String
    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CEPError.empty }
        let allowed = CharacterSet.decimalDigits.union(.whitespacesAndNewlines).union(CharacterSet(charactersIn: "-"))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { throw CEPError.invalidCharacters(value: trimmed) }
        let sanitized = trimmed.filter(\.isNumber)
        guard sanitized.count == 8 else { throw CEPError.invalidLength(value: sanitized, expected: 8) }
        guard let numericValue = Int(sanitized), Self.isInKnownBrazilianRange(numericValue) else { throw CEPError.outOfKnownPostalRange(value: sanitized) }
        self.value = sanitized
    }
    public var formatted: String { "\(prefix)-\(suffix)" }
    public var prefix: String { String(value.prefix(5)) }
    public var suffix: String { String(value.suffix(3)) }
    public var regionDigit: Int { Int(String(value[value.startIndex]))! }
    public var region: PostalRegion { PostalRegion(rawValue: regionDigit)! }
    public var distributionKind: DistributionKind {
        let s = Int(suffix)!
        switch s {
        case 0...899: return .streetRange
        case 900...959: return .specialCodes
        case 960...969: return .promotional
        case 970...989, 999: return .postOfficeUnits
        default: return .other
        }
    }
    private static let stateRanges: [StateRange] = [
        .init(state: "SP", ranges: [1_000_000...19_999_999]), .init(state: "RJ", ranges: [20_000_000...28_999_999]), .init(state: "ES", ranges: [29_000_000...29_999_999]), .init(state: "MG", ranges: [30_000_000...39_999_999]), .init(state: "BA", ranges: [40_000_000...48_999_999]), .init(state: "SE", ranges: [49_000_000...49_999_999]), .init(state: "PE", ranges: [50_000_000...56_999_999]), .init(state: "AL", ranges: [57_000_000...57_999_999]), .init(state: "PB", ranges: [58_000_000...58_999_999]), .init(state: "RN", ranges: [59_000_000...59_999_999]), .init(state: "CE", ranges: [60_000_000...63_999_999]), .init(state: "PI", ranges: [64_000_000...64_999_999]), .init(state: "MA", ranges: [65_000_000...65_999_999]), .init(state: "PA", ranges: [66_000_000...68_899_999]), .init(state: "AP", ranges: [68_900_000...68_999_999]), .init(state: "AM", ranges: [69_000_000...69_299_999, 69_400_000...69_899_999]), .init(state: "RR", ranges: [69_300_000...69_389_999]), .init(state: "AC", ranges: [69_900_000...69_999_999]), .init(state: "DF", ranges: [70_000_000...73_699_999]), .init(state: "GO", ranges: [72_800_000...76_799_999]), .init(state: "TO", ranges: [77_000_000...77_995_999]), .init(state: "MT", ranges: [78_000_000...78_899_999]), .init(state: "RO", ranges: [78_900_000...78_999_999]), .init(state: "MS", ranges: [79_000_000...79_999_999]), .init(state: "PR", ranges: [80_000_000...87_999_999]), .init(state: "SC", ranges: [88_000_000...89_999_999]), .init(state: "RS", ranges: [90_000_000...99_999_999])
    ]
    private static func isInKnownBrazilianRange(_ v: Int) -> Bool { stateRanges.contains { $0.contains(v) } }
    private struct StateRange: Sendable {
        let state: String; let ranges: [ClosedRange<Int>]
        func contains(_ cep: Int) -> Bool { ranges.contains { $0.contains(cep) } }
    }
}
