import Testing
import Foundation
@testable import social_care_s

@Suite("LookupItemCode Value Object")
struct LookupItemCodeTests {

    @Test("Deve aceitar UPPER_SNAKE_CASE valido")
    func validUpperSnakeCase() throws {
        let code = try LookupItemCode("PESSOA_REFERENCIA")
        #expect(code.value == "PESSOA_REFERENCIA")
    }

    @Test("Deve aceitar codigo simples sem underscore")
    func validSimpleCode() throws {
        let code = try LookupItemCode("INDIGENA")
        #expect(code.value == "INDIGENA")
    }

    @Test("Deve converter para uppercase automaticamente")
    func autoUppercase() throws {
        let code = try LookupItemCode("pessoa_referencia")
        #expect(code.value == "PESSOA_REFERENCIA")
    }

    @Test("Deve aceitar codigo com numeros")
    func codeWithNumbers() throws {
        let code = try LookupItemCode("TIPO_2B")
        #expect(code.value == "TIPO_2B")
    }

    @Test("Deve rejeitar string vazia")
    func emptyString() {
        #expect(throws: LookupItemCodeError.self) {
            try LookupItemCode("")
        }
    }

    @Test("Deve rejeitar string com espacos")
    func stringWithSpaces() {
        #expect(throws: LookupItemCodeError.self) {
            try LookupItemCode("PESSOA REFERENCIA")
        }
    }

    @Test("Deve rejeitar codigo comecando com numero")
    func startsWithNumber() {
        #expect(throws: LookupItemCodeError.self) {
            try LookupItemCode("2TIPO")
        }
    }

    @Test("Deve rejeitar codigo comecando com underscore")
    func startsWithUnderscore() {
        #expect(throws: LookupItemCodeError.self) {
            try LookupItemCode("_TIPO")
        }
    }

    @Test("Deve rejeitar underscores duplos")
    func doubleUnderscore() {
        #expect(throws: LookupItemCodeError.self) {
            try LookupItemCode("TIPO__DOIS")
        }
    }

    @Test("Deve rejeitar codigo terminando com underscore")
    func endsWithUnderscore() {
        #expect(throws: LookupItemCodeError.self) {
            try LookupItemCode("TIPO_")
        }
    }

    @Test("Deve trimmar whitespace")
    func trimsWhitespace() throws {
        let code = try LookupItemCode("  TIPO  ")
        #expect(code.value == "TIPO")
    }
}
