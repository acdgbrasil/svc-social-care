import Foundation
import Testing
@testable import social_care_s

@Suite("CodingConfiguration Tests")
struct CodingConfigurationTests {
    
    struct DateWrapper: Codable, Equatable {
        let date: Date
    }
    
    @Test("Deve decodificar data em formato ISO8601")
    func testDecodeISO8601() throws {
        let json = "{\"date\":\"2026-03-05T12:00:00Z\"}"
        let data = json.data(using: .utf8)!
        let decoded = try CodingConfiguration.decoder.decode(DateWrapper.self, from: data)
        
        let formatter = ISO8601DateFormatter()
        let expected = formatter.date(from: "2026-03-05T12:00:00Z")
        #expect(decoded.date == expected)
    }
    
    @Test("Deve codificar data em formato ISO8601")
    func testEncodeISO8601() throws {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: "2026-03-05T12:00:00Z")!
        let wrapper = DateWrapper(date: date)
        
        let encoded = try CodingConfiguration.encoder.encode(wrapper)
        let jsonString = String(data: encoded, encoding: .utf8)
        
        #expect(jsonString?.contains("2026-03-05T12:00:00Z") == true)
    }
}
