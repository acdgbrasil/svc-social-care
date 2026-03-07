import Testing
@testable import social_care_s
import Foundation

@Suite("Patient v2.0 Detailed Coverage")
struct PatientDetailedTests {

    @Test("Aggregated Intelligence Coverage")
    func aggregatedIntelligence() throws {
        var patient = try createValidPatient()
        
        // 1. Health Status
        let health = HealthStatus(familyId: patient.id, deficiencies: [], gestatingMembers: [], constantCareNeeds: [], foodInsecurity: true)
        patient.updateHealthStatus(health, actorId: "test-actor")
        #expect(patient.healthStatus?.foodInsecurity == true)
        
        // 2. Placement
        let history = PlacementHistory(familyId: patient.id, individualPlacements: [], collectiveSituations: .init(homeLossReport: "Lost", thirdPartyGuardReport: nil), separationChecklist: .init(adultInPrison: false, adolescentInInternment: false))
        patient.updatePlacementHistory(history, actorId: "test-actor")
        #expect(patient.placementHistory?.collectiveSituations.homeLossReport == "Lost")
        
        // 3. Intake
        let ingress = try IngressInfo(ingressTypeId: try LookupId(UUID().uuidString), originName: "Origin", originContact: "Contact", serviceReason: "Reason", linkedSocialPrograms: [])
        patient.updateIntakeInfo(ingress, actorId: "test-actor")
        #expect(patient.intakeInfo?.originName == "Origin")
    }
}

private func createValidPatient() throws -> Patient {
    let pId = PersonId()
    let prId = try LookupId(UUID().uuidString)
    let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
    return try Patient(id: PatientId(), personId: pId, diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)], familyMembers: [prMember], prRelationshipId: prId, actorId: "test-actor")
}
