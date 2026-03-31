import Testing
@testable import social_care_s
import Foundation

@Suite("CNS (Cartao Nacional de Saude) Tests")
struct CNSTests {

    private static let validCPF = try! CPF("123.456.789-09")

    // Numeros validos gerados pelo algoritmo oficial
    private static let definitivo = "100000000000007"
    private static let provisorio7 = "700000000000005"
    private static let provisorio8 = "800000000000001"
    private static let provisorio9 = "900000000000008"

    // MARK: - Definitivo (inicio 1 ou 2)

    @Test("Deve aceitar CNS definitivo valido (inicio 1)")
    func validDefinitiveCNS() throws {
        let cns = try CNS(number: Self.definitivo, cpf: Self.validCPF)
        #expect(cns.number == Self.definitivo)
        #expect(cns.cpf == Self.validCPF)
        #expect(cns.qrCode == nil)
    }

    @Test("Deve aceitar CNS definitivo valido (inicio 2)")
    func validDefinitiveCNS2() throws {
        let cns = try CNS(number: "200000000000003", cpf: Self.validCPF)
        #expect(cns.number == "200000000000003")
    }

    // MARK: - Provisorio (inicio 7, 8 ou 9)

    @Test("Deve aceitar CNS provisorio valido (inicio 7)")
    func validProvisional7() throws {
        let cns = try CNS(number: Self.provisorio7, cpf: Self.validCPF)
        #expect(cns.number == Self.provisorio7)
    }

    @Test("Deve aceitar CNS provisorio valido (inicio 8)")
    func validProvisional8() throws {
        let cns = try CNS(number: Self.provisorio8, cpf: Self.validCPF)
        #expect(cns.number == Self.provisorio8)
    }

    @Test("Deve aceitar CNS provisorio valido (inicio 9)")
    func validProvisional9() throws {
        let cns = try CNS(number: Self.provisorio9, cpf: Self.validCPF)
        #expect(cns.number == Self.provisorio9)
    }

    @Test("Deve armazenar QR Code quando informado")
    func withQRCode() throws {
        let cns = try CNS(number: Self.provisorio7, cpf: Self.validCPF, qrCode: "QR123ABC")
        #expect(cns.qrCode == "QR123ABC")
    }

    @Test("Deve ignorar QR Code vazio ou whitespace")
    func emptyQRCode() throws {
        let cns1 = try CNS(number: Self.provisorio7, cpf: Self.validCPF, qrCode: "")
        #expect(cns1.qrCode == nil)

        let cns2 = try CNS(number: Self.provisorio7, cpf: Self.validCPF, qrCode: "   ")
        #expect(cns2.qrCode == nil)
    }

    @Test("Deve formatar com espacos")
    func formatting() throws {
        let cns = try CNS(number: Self.provisorio7, cpf: Self.validCPF)
        #expect(cns.formatted == "700 0000 0000 0005")
    }

    // MARK: - Erros

    @Test("Deve rejeitar CNS vazio")
    func emptyCNS() {
        #expect(throws: CNSError.empty) {
            try CNS(number: "", cpf: Self.validCPF)
        }
    }

    @Test("Deve rejeitar CNS com tamanho incorreto")
    func wrongLength() {
        #expect(throws: CNSError.invalidLength(value: "12345", expected: 15)) {
            try CNS(number: "12345", cpf: Self.validCPF)
        }
    }

    @Test("Deve rejeitar CNS com primeiro digito invalido (3, 4, 5, 6)")
    func invalidFirstDigit() {
        #expect(throws: CNSError.self) {
            try CNS(number: "300000000000000", cpf: Self.validCPF)
        }
        #expect(throws: CNSError.self) {
            try CNS(number: "400000000000000", cpf: Self.validCPF)
        }
        #expect(throws: CNSError.self) {
            try CNS(number: "500000000000000", cpf: Self.validCPF)
        }
        #expect(throws: CNSError.self) {
            try CNS(number: "600000000000000", cpf: Self.validCPF)
        }
    }

    @Test("Deve rejeitar CNS definitivo com digito verificador incorreto")
    func invalidDefinitiveCheckDigit() {
        #expect(throws: CNSError.invalidCheckDigit(value: "100000000000001")) {
            try CNS(number: "100000000000001", cpf: Self.validCPF)
        }
    }

    @Test("Deve rejeitar CNS provisorio com soma mod 11 != 0")
    func invalidProvisionalCheckDigit() {
        #expect(throws: CNSError.invalidCheckDigit(value: "700000000000001")) {
            try CNS(number: "700000000000001", cpf: Self.validCPF)
        }
    }

    @Test("Deve sanitizar espacos e caracteres no numero")
    func sanitization() throws {
        let cns = try CNS(number: " 7000 0000 0000 005 ", cpf: Self.validCPF)
        #expect(cns.number == Self.provisorio7)
    }

    @Test("AppError mapping")
    func appErrorMapping() {
        let err = CNSError.empty.asAppError
        #expect(err.code == "CNS-001")

        let err2 = CNSError.invalidCheckDigit(value: "123").asAppError
        #expect(err2.code == "CNS-005")

        let err3 = CNSError.invalidFirstDigit(value: "300", digit: 3).asAppError
        #expect(err3.code == "CNS-003")
    }
}
