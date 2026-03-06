import Testing
@testable import social_care_s
import Foundation

@Suite("CEP (Postal Code) Tests")
struct CEPTests {

    @Test("Initialization with valid raw values")
    func validInitialization() throws {
        let cep = try CEP("88000-000")
        #expect(cep.value == "88000000")
    }

    @Test("Initialization with invalid values should throw CEPError")
    func invalidInitialization() {
        #expect(throws: CEPError.empty) { try CEP("") }
        #expect(throws: CEPError.invalidLength(value: "1", expected: 8)) { try CEP("1") }
    }
}
