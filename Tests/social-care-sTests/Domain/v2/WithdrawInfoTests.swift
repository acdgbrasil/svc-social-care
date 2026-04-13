import Testing
import Foundation
@testable import social_care_s

@Suite("WithdrawInfo Value Object")
struct WithdrawInfoTests {

    private static let actorId = "test-actor"

    // MARK: - Happy Path

    @Test("Deve criar WithdrawInfo com cada razao valida (exceto other sem notes)")
    func validCreationForEachReason() throws {
        let reasonsWithoutOther = WithdrawReason.allCases.filter { $0 != .other }
        for reason in reasonsWithoutOther {
            let info = try WithdrawInfo(
                reason: reason,
                notes: nil,
                withdrawnAt: .now,
                withdrawnBy: Self.actorId
            )
            #expect(info.reason == reason)
            #expect(info.notes == nil)
        }
    }

    @Test("Deve criar WithdrawInfo com reason=other e notes validas")
    func validCreationWithOtherReasonAndNotes() throws {
        let info = try WithdrawInfo(
            reason: .other,
            notes: "Motivo especifico documentado pelo assistente social",
            withdrawnAt: .now,
            withdrawnBy: Self.actorId
        )
        #expect(info.reason == .other)
        #expect(info.notes == "Motivo especifico documentado pelo assistente social")
    }

    @Test("Deve criar WithdrawInfo com notes de exatamente 1000 caracteres")
    func validCreationWithMaxLengthNotes() throws {
        let notes = String(repeating: "a", count: 1000)
        let info = try WithdrawInfo(
            reason: .noResponse,
            notes: notes,
            withdrawnAt: .now,
            withdrawnBy: Self.actorId
        )
        #expect(info.notes?.count == 1000)
    }

    @Test("Deve criar WithdrawInfo com notes nil e razao diferente de other")
    func validCreationWithNilNotes() throws {
        let info = try WithdrawInfo(
            reason: .patientDeclined,
            notes: nil,
            withdrawnAt: .now,
            withdrawnBy: Self.actorId
        )
        #expect(info.notes == nil)
        #expect(info.reason == .patientDeclined)
    }

    @Test("Deve criar WithdrawInfo com notes opcionais para razao diferente de other")
    func validCreationWithOptionalNotes() throws {
        let info = try WithdrawInfo(
            reason: .duplicateRecord,
            notes: "Paciente ja registrado com outro CPF",
            withdrawnAt: .now,
            withdrawnBy: Self.actorId
        )
        #expect(info.reason == .duplicateRecord)
        #expect(info.notes != nil)
    }

    // MARK: - Error Cases

    @Test("Deve falhar quando reason=other e notes eh nil")
    func failsWhenOtherReasonWithoutNotes() {
        #expect(throws: WithdrawInfoError.notesRequiredWhenReasonIsOther) {
            try WithdrawInfo(
                reason: .other,
                notes: nil,
                withdrawnAt: .now,
                withdrawnBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando reason=other e notes eh string vazia")
    func failsWhenOtherReasonWithEmptyNotes() {
        #expect(throws: WithdrawInfoError.notesRequiredWhenReasonIsOther) {
            try WithdrawInfo(
                reason: .other,
                notes: "",
                withdrawnAt: .now,
                withdrawnBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando reason=other e notes contem apenas espacos")
    func failsWhenOtherReasonWithWhitespaceNotes() {
        #expect(throws: WithdrawInfoError.notesRequiredWhenReasonIsOther) {
            try WithdrawInfo(
                reason: .other,
                notes: "   ",
                withdrawnAt: .now,
                withdrawnBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando notes excede 1000 caracteres")
    func failsWhenNotesExceedMaxLength() {
        let notes = String(repeating: "a", count: 1001)
        #expect(throws: WithdrawInfoError.notesExceedMaxLength(1001)) {
            try WithdrawInfo(
                reason: .ineligible,
                notes: notes,
                withdrawnAt: .now,
                withdrawnBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando notes excede 1000 caracteres mesmo com reason=other")
    func failsWhenOtherReasonNotesExceedMaxLength() {
        let notes = String(repeating: "b", count: 1500)
        #expect(throws: WithdrawInfoError.notesExceedMaxLength(1500)) {
            try WithdrawInfo(
                reason: .other,
                notes: notes,
                withdrawnAt: .now,
                withdrawnBy: Self.actorId
            )
        }
    }

    // MARK: - Equatable

    @Test("Deve ser Equatable")
    func equatable() throws {
        let ts = TimeStamp.now
        let a = try WithdrawInfo(reason: .patientDeclined, notes: nil, withdrawnAt: ts, withdrawnBy: "actor")
        let b = try WithdrawInfo(reason: .patientDeclined, notes: nil, withdrawnAt: ts, withdrawnBy: "actor")
        #expect(a == b)
    }
}
