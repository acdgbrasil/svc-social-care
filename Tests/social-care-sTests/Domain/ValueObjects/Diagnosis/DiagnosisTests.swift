import Testing
@testable import social_care_s
import Foundation

@Suite("Diagnosis ValueObject")
struct DiagnosisTests {

    @Test("Cria diagnóstico válido")
    func createValid() throws {
        let now = TimeStamp.now
        let icd = try ICDCode("B20.1")
        let _ = try Diagnosis(id: icd, date: now, description: "Valid", now: now)
    }

    @Test("Falha com data futura")
    func failsWithFutureDate() throws {
        let now = TimeStamp.now
        let icd = try ICDCode("B20.1")
        let futureDate = try TimeStamp(iso: "2099-01-11T12:00:00Z")
        #expect(throws: DiagnosisError.self) {
            try Diagnosis(id: icd, date: futureDate, description: "Test", now: now)
        }
    }

    @Test("Falha com descrição vazia")
    func failsWithEmptyDescription() throws {
        let now = TimeStamp.now
        let icd = try ICDCode("B20.1")
        #expect(throws: DiagnosisError.descriptionEmpty) {
            try Diagnosis(id: icd, date: now, description: "   ", now: now)
        }
    }

    @Test("Valida conversão de DiagnosisError para AppError")
    func errorConversion() {
        #expect(DiagnosisError.dateInFuture(date: "A", now: "B").asAppError.code == "DIA-001")
        #expect(DiagnosisError.dateBeforeYearZero(year: -1).asAppError.code == "DIA-002")
        #expect(DiagnosisError.descriptionEmpty.asAppError.code == "DIA-003")
    }
}
