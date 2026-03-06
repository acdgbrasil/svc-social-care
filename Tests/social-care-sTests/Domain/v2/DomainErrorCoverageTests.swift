import Testing
@testable import social_care_s
import Foundation

@Suite("Domain Error & Validation Coverage")
struct DomainErrorCoverageTests {

    @Test("CPF Error Coverage")
    func cpfErrors() {
        #expect(throws: CPFError.empty) { try CPF(" ") }
        #expect(throws: CPFError.invalidLength(value: "123", expected: 11)) { try CPF("123") }
        #expect(throws: CPFError.repeatedDigits(value: "11111111111")) { try CPF("11111111111") }
        #expect(throws: CPFError.invalidCheckDigits(value: "12345678901")) { try CPF("123.456.789-01") }
        
        let appErr = CPFError.empty.asAppError
        #expect(appErr.code == "CPF-001")
    }

    @Test("NIS Error Coverage")
    func nisErrors() {
        #expect(throws: NISError.empty) { try NIS("") }
        #expect(throws: NISError.invalidLength(value: "1", expected: 11)) { try NIS("1") }
    }

    @Test("Address Error Coverage")
    func addressErrors() {
        #expect(throws: AddressError.stateRequired) { 
            try Address(isShelter: false, residenceLocation: .urbano, state: "", city: "City") 
        }
        #expect(throws: AddressError.invalidState(value: "ZZ")) { 
            try Address(isShelter: false, residenceLocation: .urbano, state: "ZZ", city: "City") 
        }
        #expect(throws: AddressError.cityRequired) { 
            try Address(isShelter: false, residenceLocation: .urbano, state: "SP", city: "") 
        }
    }

    @Test("RGDocument Error Coverage")
    func rgErrors() throws {
        let now = TimeStamp.now
        #expect(throws: RGDocumentError.emptyNumber) { 
            try RGDocument(number: "", issuingState: "SP", issuingAgency: "SSP", issueDate: now) 
        }
        #expect(throws: RGDocumentError.invalidNumberFormat(value: "123")) { 
            try RGDocument(number: "123", issuingState: "SP", issuingAgency: "SSP", issueDate: now) 
        }
    }

    @Test("SocialIdentity Error Coverage")
    func socialIdentityErrors() throws {
        let id = try LookupId(UUID().uuidString)
        #expect(throws: SocialIdentityError.descriptionRequiredForOtherType) {
            try SocialIdentity(typeId: id, otherDescription: nil, isOtherType: true)
        }
    }
}
