import Testing
@testable import social_care_s
import Foundation

@Suite("FamilyMemberId ValueObject (FP Style - Specification)")
struct FamilyMemberIdTests {

    private let validId = "01890E18-257B-7B32-B264-93C9D46242AB"

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let validId = "01890E18-257B-7B32-B264-93C9D46242AB"

        @Test("create normaliza e valida (lowercase)")
        func normalizeAndValidate() throws {
            let id = try FamilyMemberId(validId.uppercased())
            #expect(id.description == validId.lowercased())
        }

        @Test("create falha com ID inválido")
        func failsWithInvalidId() {
            #expect(throws: FamilyMemberIdError.invalidFormat("bad-id")) {
                try FamilyMemberId("bad-id")
            }
        }
    }

    @Suite("2. Helpers de Namespace")
    struct NamespaceHelpers {
        private let validId = "01890E18-257B-7B32-B264-93C9D46242AB"

        @Test("equals compara valores de forma segura")
        func equalsComparison() throws {
            let id1 = try FamilyMemberId(validId.uppercased())
            let id2 = try FamilyMemberId(validId.lowercased())
            
            #expect(FamilyMemberId.equals(id1, id2) == true)
            #expect(id1 == id2)
        }
    }
}
