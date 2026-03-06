import Foundation

/// Value Object que representa o Cadastro de Pessoa Física (CPF) brasileiro.
public struct CPF: Codable, Equatable, Hashable, Sendable {
    
    public enum FiscalRegion: Int, Codable, Equatable, Hashable, Sendable {
        case region10 = 0, region1, region2, region3, region4, region5, region6, region7, region8, region9
        public var coveredStates: [String] {
            switch self {
            case .region1: return ["DF", "GO", "MS", "MT", "TO"]
            case .region2: return ["AC", "AM", "AP", "PA", "RO", "RR"]
            case .region3: return ["CE", "MA", "PI"]
            case .region4: return ["AL", "PB", "PE", "RN"]
            case .region5: return ["BA", "SE"]
            case .region6: return ["MG"]
            case .region7: return ["ES", "RJ"]
            case .region8: return ["SP"]
            case .region9: return ["PR", "SC"]
            case .region10: return ["RS"]
            }
        }
    }

    public let value: String
    public var baseNumber: String { String(value.prefix(8)) }
    public var fiscalRegionDigit: Int { digit(at: 8) }
    public var fiscalRegion: FiscalRegion { FiscalRegion(rawValue: fiscalRegionDigit)! }
    public var firstVerifierDigit: Int { digit(at: 9) }
    public var secondVerifierDigit: Int { digit(at: 10) }

    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CPFError.empty }
        let allowedCharacters = CharacterSet.decimalDigits.union(.whitespacesAndNewlines).union(CharacterSet(charactersIn: ".-"))
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else { throw CPFError.invalidCharacters(value: trimmed) }
        let sanitized = trimmed.filter(\.isNumber)
        guard sanitized.count == 11 else { throw CPFError.invalidLength(value: sanitized, expected: 11) }
        guard Set(sanitized).count > 1 else { throw CPFError.repeatedDigits(value: sanitized) }
        guard Self.hasValidCheckDigits(sanitized) else { throw CPFError.invalidCheckDigits(value: sanitized) }
        self.value = sanitized
    }

    public var formatted: String {
        let chars = Array(value)
        return "\(chars[0])\(chars[1])\(chars[2]).\(chars[3])\(chars[4])\(chars[5]).\(chars[6])\(chars[7])\(chars[8])-\(chars[9])\(chars[10])"
    }

    private static func hasValidCheckDigits(_ value: String) -> Bool {
        let digits = value.compactMap { Int(String($0)) }
        guard digits.count == 11 else { return false }
        let fv = firstVerifierDigit(from: digits)
        guard fv == digits[9] else { return false }
        let sv = secondVerifierDigit(from: digits, firstVerifier: fv)
        return sv == digits[10]
    }

    private static func firstVerifierDigit(from digits: [Int]) -> Int {
        verifierDigit(for: Array(digits[0..<9]), with: Array(stride(from: 10, through: 2, by: -1)))
    }

    private static func secondVerifierDigit(from digits: [Int], firstVerifier: Int) -> Int {
        verifierDigit(for: Array(digits[1..<9]) + [firstVerifier], with: Array(stride(from: 10, through: 2, by: -1)))
    }

    private static func verifierDigit(for digits: [Int], with weights: [Int]) -> Int {
        let weightedSum = zip(digits, weights).map { $0 * $1 }.reduce(0, +)
        let remainder = weightedSum % 11
        return remainder < 2 ? 0 : 11 - remainder
    }

    private func digit(at index: Int) -> Int {
        let stringIndex = value.index(value.startIndex, offsetBy: index)
        return Int(String(value[stringIndex]))!
    }
}
