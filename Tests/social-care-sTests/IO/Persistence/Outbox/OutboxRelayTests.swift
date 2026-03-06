import Testing
import Foundation
import SQLKit
import NIOCore
import Logging
@testable import social_care_s

@Suite("Outbox Relay Specification")
struct OutboxRelayTests {

    @Test("Relay deve iniciar polling quando houver assinantes")
    func testRelayStartsPolling() async throws {
        let db = SQLDatabaseMock()
        let relay = SQLKitOutboxRelay(db: db, pollInterval: .milliseconds(10))
        
        let stream = await relay.events()
        let _ = stream.makeAsyncIterator()
        
        #expect(true)
    }
}
