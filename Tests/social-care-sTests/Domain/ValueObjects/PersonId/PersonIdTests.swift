import Testing
@testable import social_care_s
import Foundation

@Suite("PersonId ValueObject (FP Style - Specification)")
struct PersonIdTests {
    
    private let validId = "01890E18-257B-7B32-B264-93C9D46242AB"
    private var lowerId: String { validId.lowercased() }

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let validId = "01890E18-257B-7B32-B264-93C9D46242AB"
        private var lowerId: String { validId.lowercased() }

        @Test("Deve permitir criar um UUID via construtor vazio (Gera novo)")
        func createWithEmptyConstructor() {
            let id = PersonId()
            let uuidString = id.description
            #expect(uuidString.count == 36)
            #expect(UUID(uuidString: uuidString) != nil, "O ID gerado deve ser um UUID válido")
        }

        @Test("Deve permitir criar um UUID via uma string já fornecida")
        func createFromString() throws {
            let id = try PersonId(validId)
            #expect(id.description == lowerId)
        }

        @Test("create normaliza (trim + lowercase)")
        func createNormalizes() throws {
            let id = try PersonId("  \(validId)  ")
            #expect(id.description == lowerId)
        }

        @Test("create falha com UUID inválido")
        func createFailsWithInvalidUUID() {
            let invalid = "invalid"
            #expect(throws: PIDError.invalidFormat(invalid)) {
                try PersonId(invalid)
            }
        }
    }

    @Suite("2. Imutabilidade e Igualdade (Value Object)")
    struct ImmutabilityAndEquality {
        private let validId = "01890E18-257B-7B32-B264-93C9D46242AB"

        @Test("Garantir imutabilidade: o valor interno não deve mudar após a criação")
        func immutability() throws {
            let id = try PersonId(validId)
            let originalValue = id.description
            #expect(id.description == originalValue)
        }

        @Test("Garantir Unicidade/Igualdade: IDs com o mesmo valor devem ser considerados iguais")
        func uniquenessByValue() throws {
            let idString = "550e8400-e29b-41d4-a716-446655440000"
            let personId1 = try PersonId(idString)
            let personId2 = try PersonId(idString)
            
            #expect(personId1 == personId2, "Devem implementar Equatable para comparação direta")
        }
    }
}
