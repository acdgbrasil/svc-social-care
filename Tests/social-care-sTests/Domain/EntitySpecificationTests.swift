import Testing
@testable import social_care_s
import Foundation

@Suite("Entities & Aggregate - Specification Validation")
struct EntitySpecificationTests {

    // MARK: - 1. FamilyMember
    @Suite("FamilyMember Spec")
    struct FamilyMemberSpec {
        @Test("1. create falha quando relationship é vazio")
        func emptyRelationship() {
            let pid = PersonId()
            #expect(throws: FamilyMemberError.invalidRelationship) {
                try FamilyMember(personId: pid, relationship: "  ", isPrimaryCaregiver: false, residesWithPatient: true)
            }
        }

        @Test("4. assignAsPrimaryCaregiver retorna nova instância")
        func mutator() throws {
            let pid = PersonId()
            var member = try FamilyMember(personId: pid, relationship: "Pai", isPrimaryCaregiver: false, residesWithPatient: true)
            
            member.assignAsPrimaryCaregiver()
            #expect(member.isPrimaryCaregiver == true)
        }
    }

    // MARK: - 5. Referral
    @Suite("Referral Spec")
    struct ReferralSpec {
        private let now = try! TimeStamp(Date())
        private let rid = ReferralId()
        private let prof = ProfessionalId()
        private let pid = PersonId()

        @Test("16. create inicia como PENDING")
        func initialStatus() throws {
            let ref = try Referral(id: rid, date: now, requestingProfessionalId: prof, referredPersonId: pid, destinationService: .cras, reason: "Test", now: now)
            #expect(ref.status == .pending)
        }

        @Test("20. complete transita para COMPLETED")
        func transition() throws {
            let ref = try Referral(id: rid, date: now, requestingProfessionalId: prof, referredPersonId: pid, destinationService: .cras, reason: "Test", now: now)
            let completed = try ref.complete()
            #expect(completed.status == .completed)
        }
    }

    // MARK: - 4. Patient Aggregate
    @Suite("Patient Aggregate Spec")
    struct PatientSpec {
        @Test("14. cria paciente com eventos iniciais e versão 1")
        func initialPatient() throws {
            let pId = PersonId()
            let appId = PatientId()
            let diag = try Diagnosis(id: try ICDCode("B20"), date: .now, description: "Test", now: .now)
            
            let patient = try Patient(id: appId, personId: pId, diagnoses: [diag], now: .now)
            
            #expect(patient.version == 1)
            #expect(patient.uncommittedEvents.count == 1)
            #expect(patient.uncommittedEvents.first is PatientCreatedEvent)
        }

        @Test("9. belongsToBoundary retorna true para o próprio paciente")
        func boundaryCheck() throws {
            let pId = PersonId()
            let appId = PatientId()
            let diag = try Diagnosis(id: try ICDCode("B20"), date: .now, description: "Test", now: .now)
            
            let patient = try Patient(id: appId, personId: pId, diagnoses: [diag], now: .now)
            
            let strangerId = PersonId()
            let nowTs = TimeStamp.now
            
            #expect(throws: PatientError.referralTargetOutsideBoundary(targetId: strangerId.description)) {
                var mutPatient = patient
                try mutPatient.addReferral(id: ReferralId(), date: nowTs, requestingProfessionalId: ProfessionalId(), referredPersonId: strangerId, destinationService: .creas, reason: "Fail", now: nowTs)
            }
        }
    }
}
