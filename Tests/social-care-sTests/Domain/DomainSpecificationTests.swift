import Testing
@testable import social_care_s
import Foundation

@Suite("Domain Layer - Full Specification Validation")
struct DomainSpecificationTests {

    // MARK: - 1. HousingCondition
    @Suite("HousingCondition Validations")
    struct HousingConditionSpec {
        @Test("1. create valida quartos vs banheiros")
        func bathroomsVsRooms() {
            #expect(throws: HousingConditionError.bathroomsExceedRooms) {
                try HousingCondition.create(type: .owned, wallMaterial: .masonry, numberOfRooms: 1, numberOfBathrooms: 2, waterSupply: .publicNetwork, electricityAccess: .meteredConnection, sewageDisposal: .publicSewer, wasteCollection: .directCollection, accessibilityLevel: .fullyAccessible, isInGeographicRiskArea: false, isInSocialConflictArea: false)
            }
        }

        @Test("2. create valida números negativos")
        func negativeRooms() {
            #expect(throws: HousingConditionError.negativeRooms) {
                try HousingCondition.create(type: .owned, wallMaterial: .masonry, numberOfRooms: -1, numberOfBathrooms: 0, waterSupply: .publicNetwork, electricityAccess: .meteredConnection, sewageDisposal: .publicSewer, wasteCollection: .directCollection, accessibilityLevel: .fullyAccessible, isInGeographicRiskArea: false, isInSocialConflictArea: false)
            }
        }
    }

    // MARK: - 2. CommunitySupportNetwork
    @Suite("CommunitySupportNetwork Validations")
    struct CommunitySupportNetworkSpec {
        @Test("3. create valida conflitos (whitespace)")
        func whitespaceConflicts() {
            #expect(throws: CommunitySupportNetworkError.familyConflictsWhitespace) {
                try CommunitySupportNetwork.create(hasRelativeSupport: true, hasNeighborSupport: true, familyConflicts: "   ", patientParticipatesInGroups: true, familyParticipatesInGroups: true, patientHasAccessToLeisure: true, facesDiscrimination: false)
            }
        }

        @Test("4. create normaliza (trim)")
        func normalizeConflicts() throws {
            let csn = try CommunitySupportNetwork.create(hasRelativeSupport: true, hasNeighborSupport: true, familyConflicts: "  Test  ", patientParticipatesInGroups: true, familyParticipatesInGroups: true, patientHasAccessToLeisure: true, facesDiscrimination: false)
            #expect(csn.familyConflicts == "Test")
        }
    }

    // MARK: - 3. Diagnosis
    @Suite("Diagnosis Validations")
    struct DiagnosisSpec {
        private let now = try! TimeStamp.create(Date())
        private let icd = try! ICDCode.create("B20")

        @Test("5. cria diagnóstico válido")
        func validDiagnosis() throws {
            let _ = try Diagnosis.create(id: icd, date: now, description: "Valid", now: now)
        }

        @Test("6. falha com data futura")
        func futureDate() throws {
            let future = try TimeStamp.create(Date().addingTimeInterval(1000))
            #expect(throws: DiagnosisError.self) {
                try Diagnosis.create(id: icd, date: future, description: "Test", now: now)
            }
        }

        @Test("7. falha com descrição vazia")
        func emptyDescription() {
            #expect(throws: DiagnosisError.descriptionEmpty) {
                try Diagnosis.create(id: icd, date: now, description: "  ", now: now)
            }
        }
    }

    // MARK: - 5. ICDCode
    @Suite("ICDCode Spec")
    struct ICDCodeSpec {
        @Test("12. create normaliza código CID")
        func normalization() throws {
            let code = try ICDCode.create("b201")
            #expect(code.value == "B20.1")
        }

        @Test("16. toDisplay formata string")
        func display() throws {
            let code = try ICDCode.create("  c509 ")
            #expect(code.value == "C50.9")
        }

        @Test("17. toNormalized remove ponto")
        func toNormalized() throws {
            let code = try ICDCode.create("C50.9")
            #expect(code.normalized == "C509")
        }
    }

    // MARK: - 8. SocialBenefitsCollection
    @Suite("SocialBenefitsCollection Spec")
    struct SocialBenefitsCollectionSpec {
        @Test("28. create valida duplicatas")
        func duplicates() throws {
            let fid = FamilyMemberId()
            let b1 = try SocialBenefit.create(benefitName: "A", amount: 100, beneficiaryId: fid)
            #expect(throws: SocialBenefitsCollectionError.duplicateBenefitNotAllowed(name: "A")) {
                try SocialBenefitsCollection.create([b1, b1])
            }
        }

        @Test("30. getTotalAmount calcula soma")
        func totalSum() throws {
            let fid = FamilyMemberId()
            let b1 = try SocialBenefit.create(benefitName: "A", amount: 100, beneficiaryId: fid)
            let b2 = try SocialBenefit.create(benefitName: "B", amount: 200, beneficiaryId: fid)
            let col = try SocialBenefitsCollection.create([b1, b2])
            #expect(col.totalAmount == 300.0)
        }
    }
}
