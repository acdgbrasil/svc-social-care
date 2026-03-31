import Foundation

/// Value Object que representa o Cartao Nacional de Saude (CNS / Cartao do SUS).
///
/// O CNS e composto pelo numero de 15 digitos (validado conforme regras do Ministerio da Saude),
/// o CPF do titular e, opcionalmente, a string do QR Code impresso no cartao fisico.
public struct CNS: Codable, Equatable, Hashable, Sendable {

    /// O numero do CNS validado (15 digitos).
    public let number: String

    /// O CPF do titular do cartao.
    public let cpf: CPF

    /// String do QR Code impresso no cartao fisico (opcional).
    public let qrCode: String?

    /// Cria um CNS validado.
    ///
    /// - Parameters:
    ///   - number: String bruta do numero CNS.
    ///   - cpf: CPF validado do titular.
    ///   - qrCode: String opcional do QR Code.
    /// - Throws: `CNSError` se o numero for invalido.
    public init(number rawValue: String, cpf: CPF, qrCode: String? = nil) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CNSError.empty }

        let sanitized = trimmed.filter(\.isNumber)
        guard sanitized.count == 15 else {
            throw CNSError.invalidLength(value: sanitized, expected: 15)
        }

        guard let firstDigit = sanitized.first.flatMap({ Int(String($0)) }) else {
            throw CNSError.invalidNumber(value: sanitized)
        }

        let isDefinitive = firstDigit == 1 || firstDigit == 2
        let isProvisional = firstDigit == 7 || firstDigit == 8 || firstDigit == 9

        guard isDefinitive || isProvisional else {
            throw CNSError.invalidFirstDigit(value: sanitized, digit: firstDigit)
        }

        let digits = sanitized.compactMap { Int(String($0)) }
        guard digits.count == 15 else {
            throw CNSError.invalidNumber(value: sanitized)
        }

        if isDefinitive {
            guard Self.validateDefinitive(digits: digits, raw: sanitized) else {
                throw CNSError.invalidCheckDigit(value: sanitized)
            }
        } else {
            guard Self.validateProvisional(digits: digits) else {
                throw CNSError.invalidCheckDigit(value: sanitized)
            }
        }

        self.number = sanitized
        self.cpf = cpf

        let normalizedQr = qrCode?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.qrCode = (normalizedQr?.isEmpty ?? true) ? nil : normalizedQr
    }

    /// Formato com espacos para exibicao: "XXX XXXX XXXX XXXX"
    public var formatted: String {
        let chars = Array(number)
        return "\(chars[0])\(chars[1])\(chars[2]) \(chars[3])\(chars[4])\(chars[5])\(chars[6]) \(chars[7])\(chars[8])\(chars[9])\(chars[10]) \(chars[11])\(chars[12])\(chars[13])\(chars[14])"
    }

    // MARK: - Validation (Definitivo — inicio 1 ou 2)

    /// Valida CNS definitivo (PIS-based, inicio 1 ou 2).
    private static func validateDefinitive(digits: [Int], raw: String) -> Bool {
        let weights = [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5]
        let pis = Array(digits[0..<11])

        let soma = zip(pis, weights).map { $0 * $1 }.reduce(0, +)
        let resto = soma % 11
        var dv = 11 - resto

        if dv == 11 { dv = 0 }

        let expected: String
        if dv == 10 {
            let soma2 = zip(pis, weights).map { $0 * $1 }.reduce(0, +) + 2
            let resto2 = soma2 % 11
            let dv2 = 11 - resto2
            expected = pis.map(String.init).joined() + "001" + String(dv2)
        } else {
            expected = pis.map(String.init).joined() + "000" + String(dv)
        }

        return raw == expected
    }

    // MARK: - Validation (Provisorio — inicio 7, 8 ou 9)

    /// Valida CNS provisorio (inicio 7, 8 ou 9) — soma ponderada mod 11 == 0.
    private static func validateProvisional(digits: [Int]) -> Bool {
        let weights = [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        let soma = zip(digits, weights).map { $0 * $1 }.reduce(0, +)
        return soma % 11 == 0
    }
}
