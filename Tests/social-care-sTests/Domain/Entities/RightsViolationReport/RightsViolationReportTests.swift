import Testing
@testable import social_care_s
import Foundation

@Suite("RightsViolationReport Entity (Specification)")
struct RightsViolationReportTests {

    private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
    private let reportId = ViolationReportId()
    private let victimId = PersonId()

    @Suite("1. Criação e Validação")
    struct CreationAndValidation {
        private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
        private let reportId = ViolationReportId()
        private let victimId = PersonId()

        @Test("Cria relatório válido")
        func createValid() throws {
            let _ = try RightsViolationReport.create(
                id: reportId,
                reportDate: now,
                incidentDate: now,
                victimId: victimId,
                violationType: .physicalViolence,
                descriptionOfFact: "Valid description",
                actionsTaken: "Valid actions",
                now: now
            )
        }

        @Test("Falha com data do relatório no futuro")
        func failsWithFutureReportDate() throws {
            let futureDate = try TimeStamp.create(iso: "2024-01-11T12:00:00Z")
            #expect(throws: RightsViolationReportError.reportDateInFuture) {
                try RightsViolationReport.create(
                    id: reportId,
                    reportDate: futureDate,
                    incidentDate: now,
                    victimId: victimId,
                    violationType: .neglect,
                    descriptionOfFact: "Test",
                    actionsTaken: "",
                    now: now
                )
            }
        }

        @Test("Falha quando incidente é posterior ao relatório")
        func failsWithIncidentAfterReport() throws {
            let incidentDate = try TimeStamp.create(iso: "2024-01-02T12:00:00Z")
            let reportDate = try TimeStamp.create(iso: "2024-01-01T12:00:00Z")
            
            #expect(throws: RightsViolationReportError.incidentAfterReport) {
                try RightsViolationReport.create(
                    id: reportId,
                    reportDate: reportDate,
                    incidentDate: incidentDate,
                    victimId: victimId,
                    violationType: .neglect,
                    descriptionOfFact: "Test",
                    actionsTaken: "",
                    now: now
                )
            }
        }

        @Test("Falha com descrição vazia")
        func failsWithEmptyDescription() {
            #expect(throws: RightsViolationReportError.emptyDescription) {
                try RightsViolationReport.create(
                    id: reportId,
                    reportDate: now,
                    incidentDate: nil,
                    victimId: victimId,
                    violationType: .other,
                    descriptionOfFact: "   ",
                    actionsTaken: "",
                    now: now
                )
            }
        }
    }

    @Suite("2. Mutação Funcional")
    struct Mutation {
        @Test("Atualiza ações gerando nova instância")
        func updateActions() throws {
            let reportId = ViolationReportId()
            let victimId = PersonId()
            let date = try TimeStamp.create(iso: "2024-01-01T10:00:00Z")
            
            let original = try RightsViolationReport.create(
                id: reportId, reportDate: date, incidentDate: nil,
                victimId: victimId, violationType: .neglect,
                descriptionOfFact: "Desc", actionsTaken: "None", now: date
            )
            
            let updated = original.updatingActions(" New Action ")
            
            #expect(updated.actionsTaken == "New Action")
            #expect(original.actionsTaken == "None")
            #expect(updated.id == original.id)
        }
    }
}
