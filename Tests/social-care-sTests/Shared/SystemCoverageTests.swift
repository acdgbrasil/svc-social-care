import Testing
@testable import social_care_s
import Foundation

@Suite("System Coverage")
struct SystemCoverageTests {

    @Test("Entrypoint main executa sem falhas")
    @MainActor
    func executableMainCoverage() {
        social_care_s.main()
    }

    @Test("Eventos de domínio podem ser instanciados")
    func patientEventsCoverage() throws {
        let patientId = try PersonId("550e8400-e29b-41d4-a716-446655440000")
        let memberId = try PersonId("550e8400-e29b-41d4-a716-446655440001")
        let now = Date()

        let created = PatientCreatedEvent(
            patientId: "patient-1",
            personId: patientId.description,
            occurredAt: now
        )
        #expect(created.patientId == "patient-1")
        #expect(created.personId == patientId.description)

        let added = FamilyMemberAddedEvent(
            memberId: memberId.description,
            patientId: "patient-1",
            relationship: "Irmã",
            occurredAt: now
        )
        #expect(added.memberId == memberId.description)

        let removed = FamilyMemberRemovedEvent(
            memberId: memberId.description,
            patientId: "patient-1",
            occurredAt: now
        )
        #expect(removed.memberId == memberId.description)

        let caregiver = PrimaryCaregiverAssignedEvent(
            patientId: "patient-1",
            caregiverId: memberId.description,
            occurredAt: now
        )
        #expect(caregiver.caregiverId == memberId.description)

        let referral = ReferralCreatedEvent(
            patientId: "patient-1",
            referralId: "ref-1",
            referredPersonId: memberId.description,
            destinationService: "CRAS",
            status: "PENDING",
            occurredAt: now
        )
        #expect(referral.referralId == "ref-1")

        let violation = RightsViolationReportedEvent(
            patientId: "patient-1",
            reportId: "rep-1",
            victimId: memberId.description,
            violationType: "NEGLECT",
            occurredAt: now
        )
        #expect(violation.reportId == "rep-1")

        let appointment = SocialCareAppointmentRegisteredEvent(
            patientId: "patient-1",
            appointmentId: "app-1",
            professionalInChargeId: "pro-1",
            type: "HOME_VISIT",
            occurredAt: now
        )
        #expect(appointment.appointmentId == "app-1")
    }
}
