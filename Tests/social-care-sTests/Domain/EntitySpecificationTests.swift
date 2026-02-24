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
            let fid = FamilyMemberId()
            #expect(throws: FamilyMemberError.invalidRelationship) {
                try FamilyMember.create(id: fid, personId: pid, relationship: "  ", isPrimaryCaregiver: false, residesWithPatient: true)
            }
        }

        @Test("4. assignAsPrimaryCaregiver retorna nova instância")
        func mutator() throws {
            let pid = PersonId()
            let fid = FamilyMemberId()
            var member = try FamilyMember.create(id: fid, personId: pid, relationship: "Pai", isPrimaryCaregiver: false, residesWithPatient: true)
            
            member.assignAsPrimaryCaregiver()
            #expect(member.isPrimaryCaregiver == true)
        }
    }

    // MARK: - 5. Referral
    @Suite("Referral Spec")
    struct ReferralSpec {
        private let now = try! TimeStamp.create(Date())
        private let rid = ReferralId()
        private let prof = ProfessionalId()
        private let pid = PersonId()

        @Test("16. create inicia como PENDING")
        func initialStatus() throws {
            let ref = try Referral.create(id: rid, date: now, requestingProfessionalId: prof, referredPersonId: pid, destinationService: .cras, reason: "Test", now: now)
            #expect(ref.status == .pending)
        }

        @Test("20. complete transita para COMPLETED")
        func transition() throws {
            let ref = try Referral.create(id: rid, date: now, requestingProfessionalId: prof, referredPersonId: pid, destinationService: .cras, reason: "Test", now: now)
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
            let diag = try Diagnosis.create(id: try ICDCode.create("B20"), date: try TimeStamp.create(Date()), description: "Test", now: try TimeStamp.create(Date()))
            
            let patient = try Patient.create(id: appId, personId: pId, diagnoses: [diag])
            
            #expect(patient.version == 1)
            #expect(patient.uncommittedEvents.count == 1)
            #expect(patient.uncommittedEvents.first is PatientCreatedEvent)
        }

        @Test("9. belongsToBoundary retorna true para o próprio paciente")
        func boundaryCheck() throws {
            let pId = PersonId()
            let appId = PatientId()
            let diag = try Diagnosis.create(id: try ICDCode.create("B20"), date: try TimeStamp.create(Date()), description: "Test", now: try TimeStamp.create(Date()))
            
            let patient = try Patient.create(id: appId, personId: pId, diagnoses: [diag])
            
            let strangerId = PersonId()
            let nowTs = try TimeStamp.create(Date())
            
            #expect(throws: PatientError.referralTargetOutsideBoundary(targetId: strangerId.description)) {
                var mutPatient = patient
                try mutPatient.createReferral(id: ReferralId(), date: nowTs, requestingProfessionalId: ProfessionalId(), referredPersonId: strangerId, destinationService: .creas, reason: "Fail", now: nowTs)
            }
        }
    }
}
