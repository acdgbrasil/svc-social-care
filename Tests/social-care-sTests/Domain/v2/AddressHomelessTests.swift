import Testing
@testable import social_care_s
import Foundation

@Suite("Address — isHomeless Tests")
struct AddressHomelessTests {

    @Test("Deve criar endereco com isHomeless = true")
    func homelessAddress() throws {
        let addr = try Address(
            isShelter: false,
            isHomeless: true,
            residenceLocation: .urbano,
            state: "SP",
            city: "Sao Paulo"
        )
        #expect(addr.isHomeless == true)
        #expect(addr.isShelter == false)
        #expect(addr.street == nil)
        #expect(addr.state == "SP")
    }

    @Test("Deve criar endereco homeless em abrigo")
    func homelessInShelter() throws {
        let addr = try Address(
            isShelter: true,
            isHomeless: true,
            residenceLocation: .urbano,
            state: "RJ",
            city: "Rio de Janeiro"
        )
        #expect(addr.isHomeless == true)
        #expect(addr.isShelter == true)
    }

    @Test("isHomeless default deve ser false")
    func defaultFalse() throws {
        let addr = try Address(
            isShelter: false,
            residenceLocation: .urbano,
            state: "MG",
            city: "Belo Horizonte"
        )
        #expect(addr.isHomeless == false)
    }

    @Test("Endereco homeless ainda exige UF e cidade")
    func homelessRequiresStateAndCity() {
        #expect(throws: AddressError.stateRequired) {
            try Address(
                isShelter: false,
                isHomeless: true,
                residenceLocation: .urbano,
                state: "",
                city: "Sao Paulo"
            )
        }
        #expect(throws: AddressError.cityRequired) {
            try Address(
                isShelter: false,
                isHomeless: true,
                residenceLocation: .urbano,
                state: "SP",
                city: ""
            )
        }
    }
}
