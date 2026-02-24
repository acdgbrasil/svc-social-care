import Testing
@testable import social_care_s
import Foundation

@Suite("Diagnosis ValueObject (FP Style - Specification)")
struct DiagnosisTests {

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let now = try! TimeStamp.create(iso: "2024-01-10T12:00:00Z")
        private let icd = try! ICDCode.create("B20.1")

        @Test("cria diagnóstico válido")
        func createValid() throws {
            let _ = try Diagnosis.create(
                id: icd,
                date: now,
                description: "Valid Description",
                now: now
            )
        }

        @Test("falha com data futura")
        func failsWithFutureDate() throws {
            let futureDate = try TimeStamp.create(iso: "2024-01-11T12:00:00Z")
            #expect(throws: DiagnosisError.self) {
                try Diagnosis.create(
                    id: icd,
                    date: futureDate,
                    description: "Test",
                    now: now
                )
            }
        }

        @Test("falha com descrição vazia")
        func failsWithEmptyDescription() {
            #expect(throws: DiagnosisError.descriptionEmpty) {
                try Diagnosis.create(
                    id: icd,
                    date: now,
                    description: "   ",
                    now: now
                )
            }
        }
    }
}
