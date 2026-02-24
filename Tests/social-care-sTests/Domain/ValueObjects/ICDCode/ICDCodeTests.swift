import Testing
@testable import social_care_s
import Foundation

@Suite("ICDCode ValueObject (FP Style - Specification)")
struct ICDCodeTests {

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {

        @Test("create normaliza código CID (ex: b201 -> B20.1)")
        func createNormalizesCode() throws {
            let code = try ICDCode("b201")
            #expect(code.value == "B20.1")
        }

        @Test("create permite códigos sem ponto quando válido (ex: A00)")
        func createAllowsCodesWithoutDot() throws {
            let code = try ICDCode("A00", autoDot: false)
            #expect(code.value == "A00")
        }

        @Test("create falha com código vazio")
        func createFailsWithEmptyCode() {
            #expect(throws: ICDCodeError.emptyCidCode) {
                try ICDCode("")
            }
        }

        @Test("create falha com padrão inválido e preenche contexto esperado")
        func createFailsWithInvalidPattern() {
            #expect(throws: ICDCodeError.self) {
                try ICDCode("AA", requiresDot: true, autoDot: false)
            }
        }
    }

    @Suite("2. Funções de Namespace (Helpers)")
    struct NamespaceHelpers {

        @Test("create formata string para exibição corretamente")
        func toDisplay() throws {
            let code = try ICDCode("  c509 ")
            #expect(code.value == "C50.9")
        }

        @Test("normalized remove ponto")
        func toNormalized() throws {
            let code = try ICDCode("C50.9")
            #expect(code.normalized == "C509")
        }
    }
    
    @Suite("3. Igualdade e Unicidade")
    struct Equality {
        @Test("Dois ICDCodes com o mesmo valor devem ser iguais")
        func equality() throws {
            let code1 = try ICDCode("b201")
            let code2 = try ICDCode("B20.1")
            
            #expect(code1 == code2)
            #expect(code1.isEquivalent(to: code2))
        }
    }
}
