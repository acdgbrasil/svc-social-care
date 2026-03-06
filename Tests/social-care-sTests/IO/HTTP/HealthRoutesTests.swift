import Testing
import Hummingbird
import HummingbirdTesting
import SQLKit
import Foundation
@testable import social_care_s

@Suite("Health Routes Integration Specification")
struct HealthRoutesTests {

    @Test("Endpoint /health deve retornar UP")
    func testLiveness() async throws {
        let world = TestWorld { router, db in
            let controller = HealthController<BasicRequestContext>(db: db)
            controller.addRoutes(to: router.group(""))
        }
        
        try await world.run { client in
            try await client.execute(uri: "/health", method: .get) { response in
                #expect(response.status == .ok)
                #expect(String(buffer: response.body) == "UP")
            }
        }
    }

    @Test("Endpoint /ready deve retornar 200 quando o banco estiver conectado")
    func testReadinessSuccess() async throws {
        let world = TestWorld { router, db in
            db.rowsToReturn = [SQLRowMock(["?column?": 1])]
            let controller = HealthController<BasicRequestContext>(db: db)
            controller.addRoutes(to: router.group(""))
        }
        
        try await world.run { client in
            try await client.execute(uri: "/ready", method: .get) { response in
                #expect(response.status == .ok)
            }
        }
    }

    @Test("Endpoint /ready deve retornar 503 quando o banco falhar")
    func testReadinessFailure() async throws {
        let world = TestWorld { router, db in
            db.errorToThrow = URLError(.cannotConnectToHost)
            let controller = HealthController<BasicRequestContext>(db: db)
            controller.addRoutes(to: router.group(""))
        }
        
        try await world.run { client in
            try await client.execute(uri: "/ready", method: .get) { response in
                #expect(response.status == .serviceUnavailable)
            }
        }
    }
}
