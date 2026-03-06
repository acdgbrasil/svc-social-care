import Foundation
import Testing
@testable import social_care_s

@Suite("TimeStamp Age Calculation Specification")
struct TimeStampAgeTests {
    
    @Test("Deve calcular idade corretamente quando já fez aniversário no ano")
    func testAgeAfterBirthday() throws {
        let birth = try TimeStamp(iso: "2000-01-01T00:00:00Z")
        let now = try TimeStamp(iso: "2024-02-01T00:00:00Z")
        #expect(birth.years(at: now) == 24)
    }
    
    @Test("Deve calcular idade corretamente quando ainda não fez aniversário no ano")
    func testAgeBeforeBirthday() throws {
        let birth = try TimeStamp(iso: "2000-12-31T00:00:00Z")
        let now = try TimeStamp(iso: "2024-02-01T00:00:00Z")
        #expect(birth.years(at: now) == 23)
    }
    
    @Test("Deve calcular idade corretamente no dia do aniversário")
    func testAgeOnBirthday() throws {
        let birth = try TimeStamp(iso: "2000-05-20T00:00:00Z")
        let now = try TimeStamp(iso: "2024-05-20T10:00:00Z")
        #expect(birth.years(at: now) == 24)
    }
    
    @Test("Deve lidar com anos bissextos (29 de Fevereiro)")
    func testLeapYearAge() throws {
        let birth = try TimeStamp(iso: "2000-02-29T00:00:00Z")
        let nowNormalYear = try TimeStamp(iso: "2023-02-28T00:00:00Z")
        let nowLeapYear = try TimeStamp(iso: "2024-02-29T00:00:00Z")
        
        // No Swift, o Calendar.dateComponents(.year...) considera que do 29/02/2000 ao 28/02/2023 passaram-se 23 anos (pois é o dia equivalente mais próximo)
        #expect(birth.years(at: nowNormalYear) == 23)
        #expect(birth.years(at: nowLeapYear) == 24)
    }
}
