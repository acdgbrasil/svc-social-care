import Testing
@testable import social_care_s
import Foundation

@Suite("NIS (Social Identification Number) Tests")
struct NISTests {

    @Test("Initialization with valid raw values")
    func validInitialization() throws {
        let nis = try NIS("12345678901")
        #expect(nis.value == "12345678901")
    }

    @Test("Initialization with invalid values should throw NISError")
    func invalidInitialization() {
        #expect(throws: NISError.empty) { try NIS("") }
        #expect(throws: NISError.invalidLength(value: "1", expected: 11)) { try NIS("1") }
    }
}
