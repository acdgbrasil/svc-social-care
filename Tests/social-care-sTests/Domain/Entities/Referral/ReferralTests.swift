import Testing
@testable import social_care_s
import Foundation

@Suite("Referral Entity (Specification)")
struct ReferralTests {

    private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
    private let refId = ReferralId()
    private let profId = ProfessionalId()
    private let personId = try! try PersonId("550e8400-e29b-41d4-a716-446655440000")

    @Suite("1. Criação e Validação")
    struct CreationAndValidation {
        private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
        private let refId = ReferralId()
        private let profId = ProfessionalId()
        private let personId = try! try PersonId("550e8400-e29b-41d4-a716-446655440000")

        @Test("Cria encaminhamento válido")
        func createValid() throws {
            let ref = try Referral.create(
                id: refId,
                date: now,
                requestingProfessionalId: profId,
                referredPersonId: personId,
                destinationService: .cras,
                reason: "Needs social assistance",
                now: now
            )
            #expect(ref.status == .pending)
        }

        @Test("Falha com data no futuro")
        func failsWithFutureDate() throws {
            let futureDate = try TimeStamp.create(iso: "2024-01-11T12:00:00Z")
            #expect(throws: ReferralError.dateInFuture) {
                try Referral.create(
                    id: refId,
                    date: futureDate,
                    requestingProfessionalId: profId,
                    referredPersonId: personId,
                    destinationService: .cras,
                    reason: "Test",
                    now: now
                )
            }
        }

        @Test("Falha sem motivo informado")
        func failsWithNoReason() {
            #expect(throws: ReferralError.reasonMissing) {
                try Referral.create(
                    id: refId,
                    date: now,
                    requestingProfessionalId: profId,
                    referredPersonId: personId,
                    destinationService: .cras,
                    reason: "   ",
                    now: now
                )
            }
        }
    }

    @Suite("2. Ciclo de Vida e Transições")
    struct LifeCycle {
        private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
        private let refId = ReferralId()
        private let profId = ProfessionalId()
        private let personId = try! try PersonId("550e8400-e29b-41d4-a716-446655440000")

        @Test("Completa um encaminhamento pendente")
        func completeReferral() throws {
            let ref = try Referral.create(
                id: refId, date: now, requestingProfessionalId: profId,
                referredPersonId: personId, destinationService: .cras,
                reason: "Test", now: now
            )
            
            let completed = try ref.complete()
            #expect(completed.status == .completed)
        }

        @Test("Cancela um encaminhamento pendente")
        func cancelReferral() throws {
            let ref = try Referral.create(
                id: refId, date: now, requestingProfessionalId: profId,
                referredPersonId: personId, destinationService: .cras,
                reason: "Test", now: now
            )
            
            let cancelled = try ref.cancel()
            #expect(cancelled.status == .cancelled)
        }

        @Test("Falha ao transitar de um estado final (Completed)")
        func failTransitionFromCompleted() throws {
            let ref = try Referral.create(
                id: refId, date: now, requestingProfessionalId: profId,
                referredPersonId: personId, destinationService: .cras,
                reason: "Test", now: now
            )
            
            let completed = try ref.complete()
            #expect(throws: ReferralError.invalidStatusTransition(from: "COMPLETED", to: "CANCELLED")) {
                try completed.cancel()
            }
        }
    }
}
