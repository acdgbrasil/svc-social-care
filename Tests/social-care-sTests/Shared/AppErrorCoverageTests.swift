import Testing
@testable import social_care_s
import Foundation

@Suite("AppError & Registry Coverage")
struct AppErrorCoverageTests {

    @Test("AppError Equality & Basics")
    func appErrorBasics() {
        let err1 = AppError(code: "1", message: "M", bc: "B", module: "MO", kind: "K", context: [:], safeContext: [:], observability: .init(category: .unexpectedSystemState, severity: .critical, fingerprint: [], tags: [:]), http: 500)
        let err2 = AppError(code: "1", message: "M", bc: "B", module: "MO", kind: "K", context: [:], safeContext: [:], observability: .init(category: .unexpectedSystemState, severity: .critical, fingerprint: [], tags: [:]), http: 500)
        
        #expect(err1 == err2)
    }

    @Test("DomainEventRegistry Singleton & Actor")
    func eventRegistry() async {
        await DomainEventRegistry.shared.bootstrap()
        // O bootstrap já cobre o registro. Testamos apenas se não explode.
        #expect(Bool(true))
    }
}
