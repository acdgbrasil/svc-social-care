import Testing
@testable import social_care_s
import Foundation

@Suite("Patient Aggregate (PoP & Specification)")
struct PatientTests {

    // MARK: - Setup Helpers
    private func makeBasicPatient() throws -> Patient {
        let pId = PersonId()
        let appId = PatientId()
        let diagnosis = try Diagnosis(
            id: try ICDCode("B20"),
            date: .now,
            description: "Initial Test",
            now: .now
        )
        
        return try Patient(id: appId, personId: pId, diagnoses: [diagnosis])
    }

    @Suite("1. Criação e Reconstituição")
    struct CoreTests {
        @Test("Cria paciente do zero com evento inicial e versão 1")
        func createFromScratch() throws {
            let pId = PersonId()
            let appId = PatientId()
            let diag = try Diagnosis(
                id: try ICDCode("A00"),
                date: .now,
                description: "Test",
                now: .now
            )

            let patient = try Patient(id: appId, personId: pId, diagnoses: [diag])
            
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
                try Patient(id: appId, personId: pId, diagnoses: [])
            }
        }

        @Test("Reconstitui agregado com estado completo sem eventos pendentes")
        func reconstituteWithState() throws {
            let pId = PersonId()
            let appId = PatientId()
            let now = TimeStamp.now
            let diag = try Diagnosis(id: try ICDCode("A00"), date: now, description: "Diag", now: now)
            let member = try FamilyMember(personId: PersonId(), relationship: "Pai", isPrimaryCaregiver: false, residesWithPatient: true)
            let referral = try Referral(
                id: ReferralId(),
                date: now,
                requestingProfessionalId: ProfessionalId(),
                referredPersonId: pId,
                destinationService: .cras,
                reason: "R",
                now: now
            )
            let report = try RightsViolationReport(
                id: ViolationReportId(),
                reportDate: now,
                incidentDate: nil,
                victimId: pId,
                violationType: .neglect,
                descriptionOfFact: "Desc",
                actionsTaken: "Ação",
                now: now
            )
            let appointment = try SocialCareAppointment(
                id: AppointmentId(),
                date: now,
                professionalInChargeId: ProfessionalId(),
                type: .homeVisit,
                summary: "Resumo",
                actionPlan: "Plano",
                now: now
            )
            let housing = try HousingCondition(
                type: .owned,
                wallMaterial: .masonry,
                numberOfRooms: 3,
                numberOfBathrooms: 1,
                waterSupply: .publicNetwork,
                electricityAccess: .meteredConnection,
                sewageDisposal: .publicSewer,
                wasteCollection: .directCollection,
                accessibilityLevel: .partiallyAccessible,
                isInGeographicRiskArea: false,
                isInSocialConflictArea: false
            )
            let socialHealth = try SocialHealthSummary(
                requiresConstantCare: false,
                hasMobilityImpairment: false,
                functionalDependencies: [],
                hasRelevantDrugTherapy: false
            )
            let benefits = try SocialBenefitsCollection([])
            let socioeconomic = try SocioEconomicSituation(
                totalFamilyIncome: 1000,
                incomePerCapita: 500,
                receivesSocialBenefit: false,
                socialBenefits: benefits,
                mainSourceOfIncome: "Trabalho",
                hasUnemployed: false
            )
            let network = try CommunitySupportNetwork(
                hasRelativeSupport: true,
                hasNeighborSupport: true,
                familyConflicts: "",
                patientParticipatesInGroups: false,
                familyParticipatesInGroups: true,
                patientHasAccessToLeisure: true,
                facesDiscrimination: false
            )

            let patient = Patient.reconstitute(
                id: appId,
                version: 7,
                personId: pId,
                diagnoses: [diag],
                familyMembers: [member],
                appointments: [appointment],
                referrals: [referral],
                violationReports: [report],
                housingCondition: housing,
                socioeconomicSituation: socioeconomic,
                communitySupportNetwork: network,
                socialHealthSummary: socialHealth
            )

            #expect(patient.id == appId)
            #expect(patient.version == 7)
            #expect(patient.uncommittedEvents.isEmpty)
            #expect(patient.familyMembers.count == 1)
            #expect(patient.appointments.count == 1)
            #expect(patient.referrals.count == 1)
            #expect(patient.violationReports.count == 1)
            #expect(patient.housingCondition != nil)
            #expect(patient.socioeconomicSituation != nil)
            #expect(patient.communitySupportNetwork != nil)
            #expect(patient.socialHealthSummary != nil)
        }
    }

    @Suite("2. Erros e Conversão")
    struct ErrorHandling {
        @Test("Valida conversão de PatientError para AppError")
        func errorConversion() {
            #expect(PatientError.initialIdIsRequired.asAppError.code == "PAT-001")
            #expect(PatientError.initialPersonIdIsRequired.asAppError.code == "PAT-002")
            #expect(PatientError.initialDiagnosesCantBeEmpty.asAppError.code == "PAT-003")
            #expect(PatientError.familyMemberAlreadyExists(memberId: "A").asAppError.code == "PAT-004")
            #expect(PatientError.familyMemberNotFound(personId: "A").asAppError.code == "PAT-005")
            #expect(PatientError.referralTargetOutsideBoundary(targetId: "A").asAppError.code == "PAT-006")
            #expect(PatientError.violationTargetOutsideBoundary(targetId: "A").asAppError.code == "PAT-007")
        }

        @Test("Valida fronteira do agregado")
        func boundaryCheck() throws {
            let patientId = PersonId()
            let diag = try Diagnosis(id: try ICDCode("B20"), date: .now, description: "X", now: .now)
            var patient = try Patient(id: PatientId(), personId: patientId, diagnoses: [diag])
            
            let memberId = PersonId()
            let member = try FamilyMember(personId: memberId, relationship: "A", isPrimaryCaregiver: false, residesWithPatient: true)
            try patient.addFamilyMember(member)
            
            let strangerId = PersonId()
            let now = TimeStamp.now
            
            // Sucesso: No agregado
            try patient.addReferral(id: ReferralId(), date: now, requestingProfessionalId: ProfessionalId(), referredPersonId: patientId, destinationService: .cras, reason: "X", now: now)
            try patient.addReferral(id: ReferralId(), date: now, requestingProfessionalId: ProfessionalId(), referredPersonId: memberId, destinationService: .creas, reason: "Y", now: now)
            
            // Falha: Fora do agregado
            #expect(throws: PatientError.referralTargetOutsideBoundary(targetId: strangerId.description)) {
                try patient.addReferral(id: ReferralId(), date: now, requestingProfessionalId: ProfessionalId(), referredPersonId: strangerId, destinationService: .education, reason: "Z", now: now)
            }
        }
    }

    @Suite("3. Gestão de Família")
    struct FamilyTests {
        @Test("Adiciona membro familiar e gera evento")
        func addFamilyMember() throws {
            var patient = try PatientTests().makeBasicPatient()
            let memberPersonId = PersonId()
            let member = try FamilyMember(
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
            
            let m1 = try FamilyMember(personId: id1, relationship: "A", isPrimaryCaregiver: true, residesWithPatient: true)
            let m2 = try FamilyMember(personId: id2, relationship: "B", isPrimaryCaregiver: false, residesWithPatient: true)
            
            try patient.addFamilyMember(m1)
            try patient.addFamilyMember(m2)
            
            try patient.assignPrimaryCaregiver(personId: id2)
            
            let member1 = patient.familyMembers.first { $0.personId == id1 }
            let member2 = patient.familyMembers.first { $0.personId == id2 }
            
            #expect(member1?.isPrimaryCaregiver == false)
            #expect(member2?.isPrimaryCaregiver == true)
            #expect(patient.version == 4) 
        }

        @Test("Remove membro existente e registra evento")
        func removeFamilyMember() throws {
            var patient = try PatientTests().makeBasicPatient()
            let id1 = PersonId()
            let member = try FamilyMember(personId: id1, relationship: "Tio", isPrimaryCaregiver: false, residesWithPatient: false)
            try patient.addFamilyMember(member)

            let previousVersion = patient.version
            try patient.removeFamilyMember(personId: id1)

            #expect(patient.familyMembers.isEmpty)
            #expect(patient.version == previousVersion + 1)
            #expect(patient.uncommittedEvents.last is FamilyMemberRemovedEvent)
        }

        @Test("Falha ao remover membro inexistente")
        func removeFamilyMemberNotFound() throws {
            var patient = try PatientTests().makeBasicPatient()
            let stranger = PersonId()
            #expect(throws: PatientError.familyMemberNotFound(personId: stranger.description)) {
                try patient.removeFamilyMember(personId: stranger)
            }
        }

        @Test("Falha ao atribuir cuidador primário para membro inexistente")
        func assignPrimaryCaregiverNotFound() throws {
            var patient = try PatientTests().makeBasicPatient()
            let stranger = PersonId()
            #expect(throws: PatientError.familyMemberNotFound(personId: stranger.description)) {
                try patient.assignPrimaryCaregiver(personId: stranger)
            }
        }
    }

    @Suite("3. Atividades e Fronteira")
    struct ActivityTests {
        @Test("Registra atendimento clínico")
        func registerAppointment() throws {
            var patient = try PatientTests().makeBasicPatient()
            let now = TimeStamp.now
            
            try patient.addAppointment(
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

        @Test("Registra denúncia dentro da fronteira do agregado")
        func addRightsViolationInsideBoundary() throws {
            var patient = try PatientTests().makeBasicPatient()
            let now = TimeStamp.now

            try patient.addRightsViolationReport(
                id: ViolationReportId(),
                reportDate: now,
                incidentDate: nil,
                victimId: patient.personId,
                violationType: .neglect,
                descriptionOfFact: "Descrição",
                actionsTaken: "Ações",
                now: now
            )

            #expect(patient.violationReports.count == 1)
            #expect(patient.uncommittedEvents.last is RightsViolationReportedEvent)
        }

        @Test("Falha ao registrar denúncia fora da fronteira do agregado")
        func addRightsViolationOutsideBoundary() throws {
            var patient = try PatientTests().makeBasicPatient()
            let now = TimeStamp.now
            let stranger = PersonId()

            #expect(throws: PatientError.violationTargetOutsideBoundary(targetId: stranger.description)) {
                try patient.addRightsViolationReport(
                    id: ViolationReportId(),
                    reportDate: now,
                    incidentDate: nil,
                    victimId: stranger,
                    violationType: .neglect,
                    descriptionOfFact: "Descrição",
                    actionsTaken: "Ações",
                    now: now
                )
            }
        }
    }

    @Suite("4. Avaliações (Assessments)")
    struct AssessmentTests {
        @Test("Atualiza condições de moradia")
        func updateHousing() throws {
            var patient = try PatientTests().makeBasicPatient()
            let condition = try HousingCondition(
                type: .rented, wallMaterial: .masonry, numberOfRooms: 2, numberOfBathrooms: 1,
                waterSupply: .publicNetwork, electricityAccess: .meteredConnection,
                sewageDisposal: .publicSewer, wasteCollection: .directCollection,
                accessibilityLevel: .fullyAccessible, isInGeographicRiskArea: false, isInSocialConflictArea: false
            )
            
            patient.updateHousingCondition(condition)
            
            #expect(patient.housingCondition != nil)
            #expect(patient.version == 2)
        }

        @Test("Atualiza avaliações socioeconômicas, rede e resumo social")
        func updateRemainingAssessments() throws {
            var patient = try PatientTests().makeBasicPatient()

            let benefits = try SocialBenefitsCollection([])
            let socioeconomic = try SocioEconomicSituation(
                totalFamilyIncome: 1200,
                incomePerCapita: 600,
                receivesSocialBenefit: false,
                socialBenefits: benefits,
                mainSourceOfIncome: "Renda informal",
                hasUnemployed: true
            )
            let network = try CommunitySupportNetwork(
                hasRelativeSupport: true,
                hasNeighborSupport: true,
                familyConflicts: "Conflito leve",
                patientParticipatesInGroups: false,
                familyParticipatesInGroups: false,
                patientHasAccessToLeisure: true,
                facesDiscrimination: false
            )
            let summary = try SocialHealthSummary(
                requiresConstantCare: true,
                hasMobilityImpairment: false,
                functionalDependencies: ["Alimentação"],
                hasRelevantDrugTherapy: true
            )

            let initialVersion = patient.version
            patient.updateSocioEconomicSituation(socioeconomic)
            patient.updateCommunitySupportNetwork(network)
            patient.updateSocialHealthSummary(summary)

            #expect(patient.socioeconomicSituation != nil)
            #expect(patient.communitySupportNetwork != nil)
            #expect(patient.socialHealthSummary != nil)
            #expect(patient.version == initialVersion + 3)
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
