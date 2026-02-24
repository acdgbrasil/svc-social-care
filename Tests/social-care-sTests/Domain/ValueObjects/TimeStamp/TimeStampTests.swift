import Testing
@testable import social_care_s
import Foundation

@Suite("TimeStamp ValueObject (FP Style - Specification)")
struct TimeStampTests {
    
    private let dateA = ISO8601DateFormatter().date(from: "2024-01-10T12:00:00Z")!

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let dateA = ISO8601DateFormatter().date(from: "2024-01-10T12:00:00Z")!

        @Test("deve criar um TimeStamp válido a partir de um objeto Date")
        func createFromDate() throws {
            let _ = try TimeStamp.create(dateA)
        }

        @Test("create(iso:) aceita string ISO válida")
        func createFromISOString() throws {
            let _ = try TimeStamp.create(iso: "2024-05-10T03:00:00Z")
        }

        @Test("deve FALHAR ao criar a partir de valor nil")
        func createWithInvalidDate() {
            #expect(throws: TimeStampError.invalidDate("nil")) {
                try TimeStamp.create(nil)
            }
        }
    }

    @Suite("2. Imutabilidade e Pureza")
    struct ImmutabilityAndPurity {
        @Test("deve ser imune a mutações no objeto Date original")
        func mutationImmunity() throws {
            var originalDate = Date(timeIntervalSince1970: 1704110400) // 2024-01-01
            let ts = try TimeStamp.create(originalDate)
            
            originalDate.addTimeInterval(3600 * 24 * 365) // +1 ano
            #expect(ts.year == 2024)
        }
    }

    @Suite("3. Funções de Comparação e Helpers")
    struct ComparisonFunctions {
        @Test("Comparações cronológicas nativas (<, ==)")
        func chronologicalComparison() throws {
            let tsA = try TimeStamp.create(iso: "2024-01-10T12:00:00Z")
            let tsEarlier = try TimeStamp.create(iso: "2024-01-09T12:00:00Z")
            let tsLater = try TimeStamp.create(iso: "2024-01-11T12:00:00Z")

            #expect(tsEarlier < tsA)
            #expect(tsA < tsLater)
            #expect(tsA == tsA)
        }

        @Test("isSameDay(as:)")
        func isSameDay() throws {
            let ts1 = try TimeStamp.create(iso: "2024-01-10T12:00:00Z")
            let ts2 = try TimeStamp.create(iso: "2024-01-10T23:59:59Z")
            #expect(ts1.isSameDay(as: ts2))
        }
    }

    @Suite("4. Getters e Formatação")
    struct FunctionalGetters {
        @Test("toISOString() retorna string formatada")
        func toISOString() throws {
            let ts = try TimeStamp.create(iso: "2024-05-10T03:00:00Z")
            #expect(ts.toISOString().contains("2024-05-10"))
        }

        @Test("year retorna ano corretamente")
        func getYear() throws {
            let ts = try TimeStamp.create(iso: "2025-01-01T00:00:00Z")
            #expect(ts.year == 2025)
        }

        @Test("Acessores UTC completos (mês, dia, hora, minuto, segundo)")
        func fullCalendarAccessors() throws {
            let ts = try TimeStamp.create(iso: "2024-05-15T14:30:45Z")
            
            #expect(ts.year == 2024)
            #expect(ts.month == 5)
            #expect(ts.day == 15)
            #expect(ts.hour == 14)
            #expect(ts.minute == 30)
            #expect(ts.seconds == 45)
        }
    }
}
