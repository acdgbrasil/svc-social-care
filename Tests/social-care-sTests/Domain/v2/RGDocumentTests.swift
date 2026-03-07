import Testing
@testable import social_care_s
import Foundation

@Suite("RG Document Tests")
struct RGDocumentTests {

    @Test("Initialization with valid values")
    func validInitialization() throws {
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

    @Test("Initialization with invalid values should throw RGDocumentError")
    func invalidInitialization() {
        let now = TimeStamp.now
        #expect(throws: RGDocumentError.emptyNumber) { 
            try RGDocument(number: "", issuingState: "SP", issuingAgency: "SSP", issueDate: now) 
        }
        #expect(throws: RGDocumentError.invalidNumberFormat(value: "123")) { 
            try RGDocument(number: "123", issuingState: "SP", issuingAgency: "SSP", issueDate: now) 
        }
    }
}
