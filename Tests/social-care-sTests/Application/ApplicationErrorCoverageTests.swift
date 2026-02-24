import Testing
@testable import social_care_s
import Foundation

@Suite("Application Error Coverage Tests")
struct ApplicationErrorCoverageTests {

    @Test("AddFamilyMemberError mapping")
    func addFamilyMemberErrorMapping() {
        #expect(AddFamilyMemberError.useCaseNotImplemented.asAppError.code == "APP-001")
        #expect(AddFamilyMemberError.repositoryNotAvailable.asAppError.code == "APP-002")
        #expect(AddFamilyMemberError.personIdAlreadyExists.asAppError.code == "APP-003")
        #expect(AddFamilyMemberError.invalidDiagnosisListFormat.asAppError.code == "APP-004")
        #expect(AddFamilyMemberError.invalidPersonIdFormat.asAppError.code == "APP-005")
        #expect(AddFamilyMemberError.persistenceMappingFailure(patientId: "X", issues: ["Y"]).asAppError.code == "APP-006")
        #expect(AddFamilyMemberError.patientNotFound.asAppError.code == "APP-007")
    }

    @Test("AssignPrimaryCaregiverError mapping")
    func assignPrimaryCaregiverErrorMapping() {
        #expect(AssignPrimaryCaregiverError.patientNotFound.asAppError.code == "APC-001")
        #expect(AssignPrimaryCaregiverError.familyMemberNotFound(personId: "X").asAppError.code == "APC-002")
        #expect(AssignPrimaryCaregiverError.invalidPersonIdFormat("X").asAppError.code == "APC-003")
        #expect(AssignPrimaryCaregiverError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "APC-004")
    }

    @Test("CreateReferralError mapping")
    func createReferralErrorMapping() {
        #expect(CreateReferralError.patientNotFound.asAppError.code == "CREF-001")
        #expect(CreateReferralError.invalidPersonIdFormat("X").asAppError.code == "CREF-002")
        #expect(CreateReferralError.invalidProfessionalIdFormat("X").asAppError.code == "CREF-003")
        #expect(CreateReferralError.invalidReferralIdFormat("X").asAppError.code == "CREF-004")
        #expect(CreateReferralError.invalidDateFormat.asAppError.code == "CREF-005")
        #expect(CreateReferralError.invalidDestinationService("X").asAppError.code == "CREF-006")
        #expect(CreateReferralError.targetOutsideBoundary("X").asAppError.code == "CREF-007")
        #expect(CreateReferralError.dateInFuture.asAppError.code == "CREF-008")
        #expect(CreateReferralError.reasonMissing.asAppError.code == "CREF-009")
        #expect(CreateReferralError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "CREF-010")
    }

    @Test("RegisterAppointmentError mapping")
    func registerAppointmentErrorMapping() {
        #expect(RegisterAppointmentError.patientNotFound.asAppError.code == "REGA-001")
        #expect(RegisterAppointmentError.invalidPersonIdFormat("X").asAppError.code == "REGA-002")
        #expect(RegisterAppointmentError.invalidProfessionalIdFormat("X").asAppError.code == "REGA-003")
        #expect(RegisterAppointmentError.invalidDateFormat.asAppError.code == "REGA-004")
        #expect(RegisterAppointmentError.invalidType(received: "X", expected: "Y").asAppError.code == "REGA-005")
        #expect(RegisterAppointmentError.missingNarrative.asAppError.code == "REGA-006")
        #expect(RegisterAppointmentError.summaryTooLong(limit: 100).asAppError.code == "REGA-007")
        #expect(RegisterAppointmentError.actionPlanTooLong(limit: 100).asAppError.code == "REGA-008")
        #expect(RegisterAppointmentError.dateInFuture.asAppError.code == "REGA-009")
        #expect(RegisterAppointmentError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "REGA-010")
    }

    @Test("RegisterPatientError mapping")
    func registerPatientErrorMapping() {
        #expect(RegisterPatientError.personIdAlreadyExists.asAppError.code == "REGP-001")
        #expect(RegisterPatientError.invalidPersonIdFormat("X").asAppError.code == "REGP-002")
        #expect(RegisterPatientError.invalidIcdCode("X").asAppError.code == "REGP-003")
        #expect(RegisterPatientError.invalidDiagnosisDate(date: "X", now: "Y").asAppError.code == "REGP-004")
        #expect(RegisterPatientError.emptyDiagnosisDescription.asAppError.code == "REGP-005")
        #expect(RegisterPatientError.initialDiagnosesRequired.asAppError.code == "REGP-006")
        #expect(RegisterPatientError.repositoryNotAvailable.asAppError.code == "REGP-007")
        #expect(RegisterPatientError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "REGP-008")
    }

    @Test("RemoveFamilyMemberError mapping")
    func removeFamilyMemberErrorMapping() {
        #expect(RemoveFamilyMemberError.patientNotFound.asAppError.code == "RFM-001")
        #expect(RemoveFamilyMemberError.familyMemberNotFound(personId: "X").asAppError.code == "RFM-002")
        #expect(RemoveFamilyMemberError.invalidPersonIdFormat("X").asAppError.code == "RFM-003")
        #expect(RemoveFamilyMemberError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "RFM-004")
    }

    @Test("ReportRightsViolationError mapping")
    func reportRightsViolationErrorMapping() {
        #expect(ReportRightsViolationError.patientNotFound.asAppError.code == "RRV-001")
        #expect(ReportRightsViolationError.invalidPersonIdFormat("X").asAppError.code == "RRV-002")
        #expect(ReportRightsViolationError.invalidViolationReportIdFormat("X").asAppError.code == "RRV-003")
        #expect(ReportRightsViolationError.invalidViolationType("X").asAppError.code == "RRV-004")
        #expect(ReportRightsViolationError.reportDateInFuture.asAppError.code == "RRV-005")
        #expect(ReportRightsViolationError.incidentAfterReport.asAppError.code == "RRV-006")
        #expect(ReportRightsViolationError.emptyDescription.asAppError.code == "RRV-007")
        #expect(ReportRightsViolationError.targetOutsideBoundary("X").asAppError.code == "RRV-008")
        #expect(ReportRightsViolationError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "RRV-009")
    }

    @Test("UpdateHousingConditionError mapping")
    func updateHousingConditionErrorMapping() {
        #expect(UpdateHousingConditionError.patientNotFound.asAppError.code == "UHC-001")
        #expect(UpdateHousingConditionError.invalidPersonIdFormat("X").asAppError.code == "UHC-002")
        #expect(UpdateHousingConditionError.invalidHousingType("X").asAppError.code == "UHC-003")
        #expect(UpdateHousingConditionError.invalidWallMaterial("X").asAppError.code == "UHC-004")
        #expect(UpdateHousingConditionError.invalidWaterSupply("X").asAppError.code == "UHC-005")
        #expect(UpdateHousingConditionError.invalidElectricityAccess("X").asAppError.code == "UHC-006")
        #expect(UpdateHousingConditionError.invalidSewageDisposal("X").asAppError.code == "UHC-007")
        #expect(UpdateHousingConditionError.invalidWasteCollection("X").asAppError.code == "UHC-008")
        #expect(UpdateHousingConditionError.invalidAccessibilityLevel("X").asAppError.code == "UHC-009")
        #expect(UpdateHousingConditionError.negativeRooms.asAppError.code == "UHC-010")
        #expect(UpdateHousingConditionError.negativeBathrooms.asAppError.code == "UHC-011")
        #expect(UpdateHousingConditionError.bathroomsExceedRooms.asAppError.code == "UHC-012")
        #expect(UpdateHousingConditionError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "UHC-013")
    }

    @Test("UpdateSocioEconomicSituationError mapping")
    func updateSocioEconomicSituationErrorMapping() {
        #expect(UpdateSocioEconomicSituationError.patientNotFound.asAppError.code == "USES-001")
        #expect(UpdateSocioEconomicSituationError.invalidPersonIdFormat("X").asAppError.code == "USES-002")
        #expect(UpdateSocioEconomicSituationError.inconsistentSocialBenefit.asAppError.code == "USES-003")
        #expect(UpdateSocioEconomicSituationError.missingSocialBenefits.asAppError.code == "USES-004")
        #expect(UpdateSocioEconomicSituationError.negativeFamilyIncome(amount: 10).asAppError.code == "USES-005")
        #expect(UpdateSocioEconomicSituationError.negativeIncomePerCapita(amount: 10).asAppError.code == "USES-006")
        #expect(UpdateSocioEconomicSituationError.emptyMainSourceOfIncome.asAppError.code == "USES-007")
        #expect(UpdateSocioEconomicSituationError.inconsistentIncomePerCapita(perCapita: 10, total: 5).asAppError.code == "USES-008")
        #expect(UpdateSocioEconomicSituationError.benefitNameEmpty.asAppError.code == "USES-009")
        #expect(UpdateSocioEconomicSituationError.amountInvalid(amount: 0).asAppError.code == "USES-010")
        #expect(UpdateSocioEconomicSituationError.duplicateBenefitNotAllowed(name: "X").asAppError.code == "USES-011")
        #expect(UpdateSocioEconomicSituationError.persistenceMappingFailure(issues: ["X"]).asAppError.code == "USES-012")
    }
}
