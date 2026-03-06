import Foundation
import Testing
@testable import social_care_s

@Suite("LookupValidating Protocol Specification")
struct LookupValidatingTests {
    
    // Mock simples para testar o contrato
    struct MockLookupValidator: LookupValidating {
        let existingIds: Set<String>
        
        func exists(id: LookupId, in table: String) async throws -> Bool {
            return existingIds.contains(id.description)
        }
    }
    
    @Test("Deve retornar verdadeiro para ID existente")
    func testIdExists() async throws {
        let existingId = UUID().uuidString
        let validator = MockLookupValidator(existingIds: [existingId.lowercased()])
        
        let id = try LookupId(existingId)
        let exists = try await validator.exists(id: id, in: "any_table")
        
        #expect(exists == true)
    }
    
    @Test("Deve retornar falso para ID inexistente")
    func testIdDoesNotExist() async throws {
        let validator = MockLookupValidator(existingIds: ["other-id"])
        
        let id = try LookupId(UUID().uuidString)
        let exists = try await validator.exists(id: id, in: "any_table")
        
        #expect(exists == false)
    }
}
