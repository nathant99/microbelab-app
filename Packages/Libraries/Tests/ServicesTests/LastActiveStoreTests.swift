import Foundation
import Testing
@testable import Services

@Suite("LastActiveStore")
@MainActor
struct LastActiveStoreTests {
    private func makeDefaults() -> UserDefaults {
        // swiftlint:disable:next force_unwrapping
        // Safety: deterministic suite name per #file; never nil under XCTest.
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }

    private func gregorian() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        // swiftlint:disable:next force_unwrapping
        // Safety: known-valid IANA identifier.
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    @Test func freshStoreHasNoLastActive() {
        let defaults = makeDefaults()
        let store = LastActiveStore(defaults: defaults, key: "test.lastActive.fresh")
        #expect(store.lastActiveAt == nil)
        #expect(store.daysSinceLastActive() == nil)
        #expect(store.shouldShowWelcomeBack() == false)
    }

    @Test func recordingStartPersists() {
        let defaults = makeDefaults()
        let store = LastActiveStore(defaults: defaults, key: "test.lastActive.persist")
        let now = Date.now
        store.recordSessionStart(now: now)
        #expect(store.lastActiveAt != nil)

        let reopened = LastActiveStore(defaults: defaults, key: "test.lastActive.persist")
        let recorded = reopened.lastActiveAt
        #expect(recorded != nil)
    }

    @Test func daysSinceLastActiveCounts() {
        let defaults = makeDefaults()
        let store = LastActiveStore(defaults: defaults, key: "test.lastActive.days")
        let calendar = gregorian()

        // swiftlint:disable:next force_unwrapping
        let baseline = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        // swiftlint:disable:next force_unwrapping
        let fourDaysLater = calendar.date(byAdding: .day, value: 4, to: baseline)!

        store.recordSessionStart(now: baseline)
        let days = store.daysSinceLastActive(now: fourDaysLater, calendar: calendar)
        #expect(days == 4)
        #expect(store.shouldShowWelcomeBack(now: fourDaysLater, calendar: calendar) == true)
    }

    @Test func belowThresholdDoesNotShowWelcomeBack() {
        let defaults = makeDefaults()
        let store = LastActiveStore(defaults: defaults, key: "test.lastActive.below")
        let calendar = gregorian()

        // swiftlint:disable:next force_unwrapping
        let baseline = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        // swiftlint:disable:next force_unwrapping
        let twoDaysLater = calendar.date(byAdding: .day, value: 2, to: baseline)!

        store.recordSessionStart(now: baseline)
        #expect(store.shouldShowWelcomeBack(now: twoDaysLater, calendar: calendar) == false)
    }

    @Test func clearResetsTimestamp() {
        let defaults = makeDefaults()
        let store = LastActiveStore(defaults: defaults, key: "test.lastActive.clear")
        store.recordSessionStart()
        store.clear()
        #expect(store.lastActiveAt == nil)
    }
}
