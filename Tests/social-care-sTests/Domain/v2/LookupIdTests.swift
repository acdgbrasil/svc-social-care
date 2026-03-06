import Foundation
import Testing
@testable import social_care_s

@Suite("LookupId Domain Specification")
struct LookupIdTests {
    
    @Test("Deve inicializar a partir de uma string UUID válida")
    func testValidUUID() throws {
        let validUUID = UUID().uuidString
        let sut = try LookupId(validUUID)
        #expect(sut.description == validUUID.lowercased())
    }
    
    @Test("Deve falhar ao inicializar com string inválida")
    func testInvalidUUID() {
        let invalid = "not-a-uuid"
        #expect(throws: LookupIdError.invalidFormat(invalid)) {
            try LookupId(invalid)
        }
    }
    
    @Test("Deve suportar igualdade entre dois IDs iguais")
    func testEquality() throws {
        let uuid = UUID().uuidString
        let id1 = try LookupId(uuid)
        let id2 = try LookupId(uuid)
        #expect(id1 == id2)
    }
    
    @Test("Deve ser Codable")
    func testCodable() throws {
        let uuid = UUID().uuidString
        let id = try LookupId(uuid)
        let data = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(LookupId.self, from: data)
        #expect(decoded == id)
    }
}
