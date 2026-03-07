import Foundation
@testable import social_care_s

actor InMemoryEventBus: EventBus {
    private(set) var publishedEvents: [any DomainEvent] = []
    private(set) var publishCallCount = 0

    func publish(_ events: [any DomainEvent]) async throws {
        publishedEvents.append(contentsOf: events)
        publishCallCount += 1
    }

    // MARK: - Test Helpers

    func eventCount() -> Int {
        publishedEvents.count
    }

    func lastEvent() -> (any DomainEvent)? {
        publishedEvents.last
    }

    func reset() {
        publishedEvents = []
        publishCallCount = 0
    }
}
