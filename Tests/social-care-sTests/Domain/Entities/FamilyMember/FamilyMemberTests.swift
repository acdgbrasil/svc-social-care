import Testing
@testable import social_care_s
import Foundation

@Suite("FamilyMember Entity (Specification)")
struct FamilyMemberTests {

    private let memberId = FamilyMemberId()
    private let personId = try! PersonId("550e8400-e29b-41d4-a716-446655440000")

    @Suite("1. Criação e Validação")
    struct CreationAndValidation {
        private let memberId = FamilyMemberId()
        private let personId = try! PersonId("550e8400-e29b-41d4-a716-446655440000")

        @Test("Cria membro familiar válido")
        func createValid() throws {
            let member = try FamilyMember.create(
                id: memberId,
                personId: personId,
                relationship: " Mother ",
                isPrimaryCaregiver: false,
                residesWithPatient: true
            )
            #expect(member.relationship == "Mother")
        }

        @Test("Falha com relacionamento vazio")
        func failsWithNoRelationship() {
            #expect(throws: FamilyMemberError.invalidRelationship) {
                try FamilyMember.create(
                    id: memberId,
                    personId: personId,
                    relationship: "   ",
                    isPrimaryCaregiver: false,
                    residesWithPatient: true
                )
            }
        }
    }

    @Suite("2. Mutação Funcional")
    struct Mutation {
        private let memberId = FamilyMemberId()
        private let personId = try! PersonId("550e8400-e29b-41d4-a716-446655440000")

        @Test("Atribui e revoga cuidador principal gerando novas instâncias")
        func caregiverTransitions() throws {
            var member = try FamilyMember.create(
                id: memberId, personId: personId, relationship: "Father",
                isPrimaryCaregiver: false, residesWithPatient: true
            )
            
            // Atribuindo
            member.assignAsPrimaryCaregiver()
            #expect(member.isPrimaryCaregiver == true)
            
            // Revogando
            member.revokePrimaryCaregiver()
            #expect(member.isPrimaryCaregiver == false)
        }
    }
}
