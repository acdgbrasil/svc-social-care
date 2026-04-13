import Testing
import Foundation
@testable import social_care_s

@Suite("DischargeInfo Value Object")
struct DischargeInfoTests {

    private static let actorId = "test-actor"

    // MARK: - Happy Path

    @Test("Deve criar DischargeInfo com cada razao valida (exceto other sem notes)")
    func validCreationForEachReason() throws {
        let reasonsWithoutOther = DischargeReason.allCases.filter { $0 != .other }
        for reason in reasonsWithoutOther {
            let info = try DischargeInfo(
                reason: reason,
                notes: nil,
                dischargedAt: .now,
                dischargedBy: Self.actorId
            )
            #expect(info.reason == reason)
            #expect(info.notes == nil)
        }
    }

    @Test("Deve criar DischargeInfo com reason=other e notes validas")
    func validCreationWithOtherReasonAndNotes() throws {
        let info = try DischargeInfo(
            reason: .other,
            notes: "Motivo especifico documentado pelo assistente social",
            dischargedAt: .now,
            dischargedBy: Self.actorId
        )
        #expect(info.reason == .other)
        #expect(info.notes == "Motivo especifico documentado pelo assistente social")
    }

    @Test("Deve criar DischargeInfo com notes opcionais para razao diferente de other")
    func validCreationWithOptionalNotes() throws {
        let info = try DischargeInfo(
            reason: .caseObjectiveAchieved,
            notes: "Paciente atingiu todos os objetivos do plano de cuidados",
            dischargedAt: .now,
            dischargedBy: Self.actorId
        )
        #expect(info.reason == .caseObjectiveAchieved)
        #expect(info.notes != nil)
    }

    @Test("Deve criar DischargeInfo com notes de exatamente 1000 caracteres")
    func validCreationWithMaxLengthNotes() throws {
        let notes = String(repeating: "a", count: 1000)
        let info = try DischargeInfo(
            reason: .relocation,
            notes: notes,
            dischargedAt: .now,
            dischargedBy: Self.actorId
        )
        #expect(info.notes?.count == 1000)
    }

    @Test("Deve criar DischargeInfo com notes nil e razao diferente de other")
    func validCreationWithNilNotes() throws {
        let info = try DischargeInfo(
            reason: .death,
            notes: nil,
            dischargedAt: .now,
            dischargedBy: Self.actorId
        )
        #expect(info.notes == nil)
        #expect(info.reason == .death)
    }

    // MARK: - Error Cases

    @Test("Deve falhar quando reason=other e notes eh nil")
    func failsWhenOtherReasonWithoutNotes() {
        #expect(throws: DischargeInfoError.notesRequiredWhenReasonIsOther) {
            try DischargeInfo(
                reason: .other,
                notes: nil,
                dischargedAt: .now,
                dischargedBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando reason=other e notes eh string vazia")
    func failsWhenOtherReasonWithEmptyNotes() {
        #expect(throws: DischargeInfoError.notesRequiredWhenReasonIsOther) {
            try DischargeInfo(
                reason: .other,
                notes: "",
                dischargedAt: .now,
                dischargedBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando reason=other e notes contem apenas espacos")
    func failsWhenOtherReasonWithWhitespaceNotes() {
        #expect(throws: DischargeInfoError.notesRequiredWhenReasonIsOther) {
            try DischargeInfo(
                reason: .other,
                notes: "   ",
                dischargedAt: .now,
                dischargedBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando notes excede 1000 caracteres")
    func failsWhenNotesExceedMaxLength() {
        let notes = String(repeating: "a", count: 1001)
        #expect(throws: DischargeInfoError.notesExceedMaxLength(1001)) {
            try DischargeInfo(
                reason: .caseObjectiveAchieved,
                notes: notes,
                dischargedAt: .now,
                dischargedBy: Self.actorId
            )
        }
    }

    @Test("Deve falhar quando notes excede 1000 caracteres mesmo com reason=other")
    func failsWhenOtherReasonNotesExceedMaxLength() {
        let notes = String(repeating: "b", count: 1500)
        #expect(throws: DischargeInfoError.notesExceedMaxLength(1500)) {
            try DischargeInfo(
                reason: .other,
                notes: notes,
                dischargedAt: .now,
                dischargedBy: Self.actorId
            )
        }
    }

    // MARK: - Equatable / Codable

    @Test("Deve ser Equatable")
    func equatable() throws {
        let ts = TimeStamp.now
        let a = try DischargeInfo(reason: .death, notes: nil, dischargedAt: ts, dischargedBy: "actor")
        let b = try DischargeInfo(reason: .death, notes: nil, dischargedAt: ts, dischargedBy: "actor")
        #expect(a == b)
    }
}
