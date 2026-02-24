import Testing
@testable import social_care_s
import Foundation

@Suite("SocialCareAppointment Entity (Specification)")
struct SocialCareAppointmentTests {

    private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
    private let appId = AppointmentId()
    private let profId = ProfessionalId()

    @Suite("1. Criação e Validação")
    struct CreationAndValidation {
        private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
        private let appId = AppointmentId()
        private let profId = ProfessionalId()

        @Test("Cria atendimento válido")
        func createValid() throws {
            let _ = try SocialCareAppointment.create(
                id: appId,
                date: now,
                professionalInChargeId: profId,
                type: .homeVisit,
                summary: "Summary test",
                actionPlan: "Action plan test",
                now: now
            )
        }

        @Test("Falha com data futura")
        func failsWithFutureDate() throws {
            let futureDate = try TimeStamp.create(iso: "2024-01-11T12:00:00Z")
            #expect(throws: SocialCareAppointmentError.dateInFuture) {
                try SocialCareAppointment.create(
                    id: appId,
                    date: futureDate,
                    professionalInChargeId: profId,
                    type: .homeVisit,
                    summary: "Test",
                    actionPlan: "Test",
                    now: now
                )
            }
        }

        @Test("Falha sem narrativa (resumo e plano vazios)")
        func failsWithNoNarrative() {
            #expect(throws: SocialCareAppointmentError.missingNarrative) {
                try SocialCareAppointment.create(
                    id: appId,
                    date: now,
                    professionalInChargeId: profId,
                    type: .homeVisit,
                    summary: "   ",
                    actionPlan: "",
                    now: now
                )
            }
        }

        @Test("Falha com resumo muito longo")
        func summaryTooLong() {
            let longSummary = String(repeating: "A", count: 501)
            #expect(throws: SocialCareAppointmentError.summaryTooLong(limit: 500)) {
                try SocialCareAppointment.create(
                    id: appId,
                    date: now,
                    professionalInChargeId: profId,
                    type: .homeVisit,
                    summary: longSummary,
                    actionPlan: "Test",
                    now: now
                )
            }
        }
    }

    @Suite("2. Identidade e Igualdade")
    struct Identity {
        @Test("Igualdade baseada apenas no ID")
        func equalityById() throws {
            let id = AppointmentId()
            let profId = ProfessionalId()
            let date = try TimeStamp.create(iso: "2024-01-01T10:00:00Z")
            
            let app1 = try SocialCareAppointment.create(
                id: id, date: date, professionalInChargeId: profId,
                type: .homeVisit, summary: "A", actionPlan: "B", now: date
            )
            
            let app2 = try SocialCareAppointment.create(
                id: id, date: date, professionalInChargeId: profId,
                type: .phoneCall, summary: "C", actionPlan: "D", now: date
            )
            
            #expect(app1 == app2)
        }
    }
}
