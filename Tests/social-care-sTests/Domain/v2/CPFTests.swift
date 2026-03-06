import Testing
@testable import social_care_s
import Foundation

@Suite("CPF (Brazilian Individual Taxpayer ID) Tests")
struct CPFTests {

    @Test("Initialization with valid raw values")
    func validInitialization() throws {
        // Formatted input
        let cpf1 = try CPF("123.456.789-09")
        #expect(cpf1.value == "12345678909")
        #expect(cpf1.formatted == "123.456.789-09")
        
        // Unformatted input
        let cpf2 = try CPF("12345678909")
        #expect(cpf2.value == "12345678909")
    }

    @Test("Initialization with invalid values should throw CPFError")
    func invalidInitialization() {
        #expect(throws: CPFError.empty) { try CPF(" ") }
        #expect(throws: CPFError.invalidLength(value: "123", expected: 11)) { try CPF("123") }
        #expect(throws: CPFError.repeatedDigits(value: "11111111111")) { try CPF("11111111111") }
        #expect(throws: CPFError.invalidCheckDigits(value: "12345678901")) { try CPF("123.456.789-01") }
    }

    @Test("Fiscal Region calculation")
    func fiscalRegion() throws {
        let cpf = try CPF("123.456.789-09") // 9th digit is 9
        #expect(cpf.fiscalRegionDigit == 9)
        #expect(cpf.fiscalRegion == .region9)
        #expect(cpf.fiscalRegion.coveredStates.contains("SC"))
    }
    
    @Test("AppError mapping")
    func appErrorMapping() {
        let appErr = CPFError.empty.asAppError
        #expect(appErr.code == "CPF-001")
    }
}
