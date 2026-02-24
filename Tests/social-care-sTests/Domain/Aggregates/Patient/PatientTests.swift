import Testing
@testable import social_care_s
import Foundation

@Suite("Patient Aggregate (PoP & Specification)")
struct PatientTests {

    // MARK: - Setup Helpers
    private func makeBasicPatient() throws -> Patient {
        let pId = PersonId()
        let appId = PatientId()
        let diagnosis = try Diagnosis.create(
            id: try ICDCode.create("B20"),
            date: try TimeStamp.create(Date()),
            description: "Initial Test",
            now: try TimeStamp.create(Date())
        )
        
        return try Patient.create(id: appId, personId: pId, diagnoses: [diagnosis])
    }

    @Suite("1. Criação e Reconstituição")
    struct CoreTests {
        @Test("Cria paciente do zero com evento inicial e versão 1")
        func createFromScratch() throws {
            let pId = PersonId()
            let appId = PatientId()
            let diag = try Diagnosis.create(
                id: try ICDCode.create("A00"),
                date: try TimeStamp.create(Date()),
                description: "Test",
                now: try TimeStamp.create(Date())
            )

            let patient = try Patient.create(id: appId, personId: pId, diagnoses: [diag])
            
            #expect(patient.id == appId)
            #expect(patient.version == 1) 
            #expect(patient.uncommittedEvents.count == 1)
            #expect(patient.uncommittedEvents.first is PatientCreatedEvent)
        }

        @Test("Falha ao criar paciente sem diagnósticos")
        func createWithNoDiagnoses() throws {
            let pId = PersonId()
            let appId = PatientId()
            
            #expect(throws: PatientError.initialDiagnosesCantBeEmpty) {
                try Patient.create(id: appId, personId: pId, diagnoses: [])
            }
        }
    }

    @Suite("2. Gestão de Família")
    struct FamilyTests {
        @Test("Adiciona membro familiar e gera evento")
        func addFamilyMember() throws {
            var patient = try PatientTests().makeBasicPatient()
            let memberPersonId = PersonId()
            let memberId = FamilyMemberId()
            let member = try FamilyMember.create(
                id: memberId,
                personId: memberPersonId,
                relationship: "Mother",
                isPrimaryCaregiver: false,
                residesWithPatient: true
            )

            try patient.addFamilyMember(member)
            
            #expect(patient.familyMembers.count == 1)
            #expect(patient.version == 2)
            #expect(patient.uncommittedEvents.count == 2)
            #expect(patient.uncommittedEvents.last is FamilyMemberAddedEvent)
        }

        @Test("Define cuidador principal e revoga outros")
        func assignPrimaryCaregiver() throws {
            var patient = try PatientTests().makeBasicPatient()
            let id1 = PersonId()
            let id2 = PersonId()
            
            let m1 = try FamilyMember.create(id: FamilyMemberId(), personId: id1, relationship: "A", isPrimaryCaregiver: true, residesWithPatient: true)
            let m2 = try FamilyMember.create(id: FamilyMemberId(), personId: id2, relationship: "B", isPrimaryCaregiver: false, residesWithPatient: true)
            
            try patient.addFamilyMember(m1)
            try patient.addFamilyMember(m2)
            
            try patient.assignPrimaryCaregiver(personId: id2)
            
            let member1 = patient.familyMembers.first { $0.personId == id1 }
            let member2 = patient.familyMembers.first { $0.personId == id2 }
            
            #expect(member1?.isPrimaryCaregiver == false)
            #expect(member2?.isPrimaryCaregiver == true)
            #expect(patient.version == 4) 
        }
    }

    @Suite("3. Atividades e Fronteira")
    struct ActivityTests {
        @Test("Registra atendimento clínico")
        func registerAppointment() throws {
            var patient = try PatientTests().makeBasicPatient()
            let now = try TimeStamp.create(Date())
            
            try patient.registerAppointment(
                id: AppointmentId(),
                date: now,
                professionalInChargeId: ProfessionalId(),
                type: .homeVisit,
                summary: "Notes",
                actionPlan: "Plan",
                now: now
            )
            
            #expect(patient.appointments.count == 1)
            #expect(patient.version == 2)
            #expect(patient.uncommittedEvents.last is SocialCareAppointmentRegisteredEvent)
        }
    }

    @Suite("4. Avaliações (Assessments)")
    struct AssessmentTests {
        @Test("Atualiza condições de moradia")
        func updateHousing() throws {
            var patient = try PatientTests().makeBasicPatient()
            let condition = try HousingCondition.create(
                type: .rented, wallMaterial: .masonry, numberOfRooms: 2, numberOfBathrooms: 1,
                waterSupply: .publicNetwork, electricityAccess: .meteredConnection,
                sewageDisposal: .publicSewer, wasteCollection: .directCollection,
                accessibilityLevel: .fullyAccessible, isInGeographicRiskArea: false, isInSocialConflictArea: false
            )
            
            patient.updateHousingCondition(condition)
            
            #expect(patient.housingCondition != nil)
            #expect(patient.version == 2)
        }
    }

    @Suite("5. Ciclo de Vida de Eventos")
    struct EventLifecycleTests {
        @Test("Limpa eventos após persistência")
        func clearEvents() throws {
            var patient = try PatientTests().makeBasicPatient()
            #expect(patient.uncommittedEvents.count == 1)
            
            patient.clearEvents()
            
            #expect(patient.uncommittedEvents.isEmpty)
            #expect(patient.version == 1)
        }
    }
}
