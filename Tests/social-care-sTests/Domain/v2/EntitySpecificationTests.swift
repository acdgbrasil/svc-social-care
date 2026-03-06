import Testing
@testable import social_care_s
import Foundation

@Suite("Entities & Aggregate - Specification Validation v2")
struct EntitySpecificationTests {

    // MARK: - 1. FamilyMember
    @Suite("FamilyMember Spec")
    struct FamilyMemberSpec {
        @Test("create deve inicializar com relationshipId e birthDate")
        func validCreation() throws {
            let pid = PersonId()
            let rid = try LookupId(UUID().uuidString)
            let birth = try TimeStamp(iso: "2000-01-01T00:00:00Z")
            
            let member = try FamilyMember(
                personId: pid, 
                relationshipId: rid, 
                isPrimaryCaregiver: false, 
                residesWithPatient: true,
                birthDate: birth
            )
            
            #expect(member.personId == pid)
            #expect(member.relationshipId == rid)
            #expect(member.birthDate == birth)
        }

        @Test("assignAsPrimaryCaregiver deve alterar estado interno")
        func mutator() throws {
            let pid = PersonId()
            let rid = try LookupId(UUID().uuidString)
            var member = try FamilyMember(
                personId: pid, 
                relationshipId: rid, 
                isPrimaryCaregiver: false, 
                residesWithPatient: true,
                birthDate: .now
            )
            
            member.assignAsPrimaryCaregiver()
            #expect(member.isPrimaryCaregiver == true)
        }
    }

    // MARK: - 5. Referral
    @Suite("Referral Spec")
    struct ReferralSpec {
        private let now = TimeStamp.now
        private let rid = ReferralId()
        private let prof = ProfessionalId()
        private let pid = PersonId()

        @Test("create inicia como PENDING")
        func initialStatus() throws {
            let ref = try Referral(id: rid, date: now, requestingProfessionalId: prof, referredPersonId: pid, destinationService: .cras, reason: "Test", now: now)
            #expect(ref.status == .pending)
        }

        @Test("complete transita para COMPLETED")
        func transition() throws {
            var ref = try Referral(id: rid, date: now, requestingProfessionalId: prof, referredPersonId: pid, destinationService: .cras, reason: "Test", now: now)
            try ref.complete()
            #expect(ref.status == .completed)
        }
    }

    // MARK: - 4. Patient Aggregate
    @Suite("Patient Aggregate Spec")
    struct PatientSpec {
        @Test("cria paciente com PR validada e gera evento")
        func initialPatient() throws {
            let pId = PersonId()
            let appId = PatientId()
            let prId = try LookupId(UUID().uuidString)
            let diag = try Diagnosis(id: try ICDCode("B20"), date: .now, description: "Test", now: .now)
            
            // Criando com um membro que é a PR
            let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
            
            let patient = try Patient(
                id: appId, 
                personId: pId, 
                diagnoses: [diag], 
                familyMembers: [prMember],
                prRelationshipId: prId,
                now: .now
            )
            
            #expect(patient.version == 1)
            #expect(patient.uncommittedEvents.count == 1)
            #expect(patient.uncommittedEvents.first is PatientCreatedEvent)
        }

        @Test("falha ao criar paciente sem Pessoa de Referência")
        func prValidation() throws {
            let pId = PersonId()
            let prId = try LookupId(UUID().uuidString)
            let otherId = try LookupId(UUID().uuidString)
            let diag = try Diagnosis(id: try ICDCode("B20"), date: .now, description: "Test", now: .now)
            
            let member = try FamilyMember(personId: PersonId(), relationshipId: otherId, isPrimaryCaregiver: false, residesWithPatient: true, birthDate: .now)
            
            #expect(throws: PatientError.mustHaveExactlyOnePrimaryReference) {
                try Patient(
                    id: PatientId(), 
                    personId: pId, 
                    diagnoses: [diag], 
                    familyMembers: [member],
                    prRelationshipId: prId
                )
            }
        }
    }
}
