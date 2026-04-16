import Testing
@testable import social_care_s
import Foundation

@Suite("RG Document Tests")
struct RGDocumentTests {

    @Test("Initialization with valid numeric RG")
    func validNumericInitialization() throws {
        let now = TimeStamp.now
        let rg = try RGDocument(
            number: "12.345.678-2",
            issuingState: "SP",
            issuingAgency: "SSP",
            issueDate: now
        )
        #expect(rg.number == "123456782")
        #expect(rg.issuingState == "SP")
    }

    @Test("Initialization with valid alphanumeric RG")
    func validAlphanumericInitialization() throws {
        let now = TimeStamp.now
        let rg = try RGDocument(
            number: "MG-15.234.567",
            issuingState: "MG",
            issuingAgency: "PC",
            issueDate: now
        )
        #expect(rg.number == "MG15234567")
    }

    @Test("Initialization with short valid RG")
    func validShortInitialization() throws {
        let now = TimeStamp.now
        let rg = try RGDocument(
            number: "1234",
            issuingState: "RJ",
            issuingAgency: "DETRAN",
            issueDate: now
        )
        #expect(rg.number == "1234")
    }

    @Test("Empty number should throw")
    func emptyNumber() {
        let now = TimeStamp.now
        #expect(throws: RGDocumentError.emptyNumber) {
            try RGDocument(number: "", issuingState: "SP", issuingAgency: "SSP", issueDate: now)
        }
    }

    @Test("Too short number should throw")
    func tooShortNumber() {
        let now = TimeStamp.now
        #expect(throws: RGDocumentError.invalidNumberFormat(value: "12")) {
            try RGDocument(number: "12", issuingState: "SP", issuingAgency: "SSP", issueDate: now)
        }
    }

    @Test("Too long number should throw")
    func tooLongNumber() {
        let now = TimeStamp.now
        #expect(throws: RGDocumentError.invalidNumberFormat(value: "1234567890123456")) {
            try RGDocument(number: "1234567890123456", issuingState: "SP", issuingAgency: "SSP", issueDate: now)
        }
    }

    @Test("Special characters in number should throw")
    func specialCharsInNumber() {
        let now = TimeStamp.now
        #expect(throws: RGDocumentError.invalidNumberFormat(value: "12@456")) {
            try RGDocument(number: "12@456", issuingState: "SP", issuingAgency: "SSP", issueDate: now)
        }
    }
}
