import Foundation
import Testing
@testable import Services

@Suite("StreakStore")
@MainActor
struct StreakStoreTests {
    private func makeDefaults() -> UserDefaults {
        // swiftlint:disable:next force_unwrapping
        // Safety: deterministic suite name per #file; never nil under XCTest.
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }

    @Test func freshStoreReturnsDefaultFreezes() {
        let defaults = makeDefaults()
        let store = StreakStore(defaults: defaults, keyPrefix: "test.streak.fresh", startingFreezes: 2)
        #expect(store.currentStreak == 0)
        #expect(store.longestStreak == 0)
        #expect(store.availableFreezes == 2)
        #expect(store.lastRecordedAt == nil)
    }

    @Test func savedStatePersistsAcrossInstances() {
        let defaults = makeDefaults()
        let keyPrefix = "test.streak.persist"
        let now = Date.now

        let first = StreakStore(defaults: defaults, keyPrefix: keyPrefix)
        first.save(currentStreak: 7, longestStreak: 12, availableFreezes: 1, recordedAt: now)

        let reopened = StreakStore(defaults: defaults, keyPrefix: keyPrefix)
        #expect(reopened.currentStreak == 7)
        #expect(reopened.longestStreak == 12)
        #expect(reopened.availableFreezes == 1)
        #expect(reopened.lastRecordedAt != nil)
    }

    @Test func availableFreezesRespectsExplicitlyPersistedZero() {
        // Default fallback (2) only fires on never-written. Once the kid
        // burns both freezes, the store must persist 0 — not drift back to 2.
        let defaults = makeDefaults()
        let store = StreakStore(defaults: defaults, keyPrefix: "test.streak.zero")
        store.save(currentStreak: 4, longestStreak: 4, availableFreezes: 0, recordedAt: .now)
        let reopened = StreakStore(defaults: defaults, keyPrefix: "test.streak.zero")
        #expect(reopened.availableFreezes == 0)
    }

    @Test func clearResetsAllCounters() {
        let defaults = makeDefaults()
        let store = StreakStore(defaults: defaults, keyPrefix: "test.streak.clear")
        store.save(currentStreak: 5, longestStreak: 5, availableFreezes: 2, recordedAt: .now)
        store.clear()
        #expect(store.currentStreak == 0)
        #expect(store.longestStreak == 0)
        // Cleared → fallback returns default starting freezes.
        #expect(store.availableFreezes == 2)
        #expect(store.lastRecordedAt == nil)
    }
}

@Suite("StreakRescue")
struct StreakRescueTests {
    private func gregorian() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        // swiftlint:disable:next force_unwrapping
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    @Test func nilLastRecordedAtYieldsNone() {
        let rescue = StreakRescue.from(lastRecordedAt: nil, priorStreak: 5)
        #expect(rescue == .none)
    }

    @Test func zeroPriorStreakYieldsNone() {
        let rescue = StreakRescue.from(
            lastRecordedAt: .now.addingTimeInterval(-10 * 24 * 3600),
            priorStreak: 0
        )
        #expect(rescue == .none)
    }

    @Test func sameDayYieldsNone() {
        let calendar = gregorian()
        // swiftlint:disable:next force_unwrapping
        let baseline = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        // swiftlint:disable:next force_unwrapping
        let sameDay = calendar.date(byAdding: .hour, value: 6, to: baseline)!
        let rescue = StreakRescue.from(
            lastRecordedAt: baseline,
            priorStreak: 8,
            now: sameDay,
            calendar: calendar
        )
        #expect(rescue == .none)
    }

    @Test func consecutiveDayYieldsNone() {
        // Streak continues — no rescue needed.
        let calendar = gregorian()
        // swiftlint:disable:next force_unwrapping
        let yesterday = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        // swiftlint:disable:next force_unwrapping
        let today = calendar.date(byAdding: .day, value: 1, to: yesterday)!
        let rescue = StreakRescue.from(
            lastRecordedAt: yesterday,
            priorStreak: 4,
            now: today,
            calendar: calendar
        )
        #expect(rescue == .none)
    }

    @Test func twoDayGapSurfacesLapsedRescue() {
        let calendar = gregorian()
        // swiftlint:disable:next force_unwrapping
        let baseline = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        // swiftlint:disable:next force_unwrapping
        let twoDaysLater = calendar.date(byAdding: .day, value: 2, to: baseline)!
        let rescue = StreakRescue.from(
            lastRecordedAt: baseline,
            priorStreak: 12,
            now: twoDaysLater,
            calendar: calendar
        )
        #expect(rescue == .lapsed(priorStreak: 12))
    }

    @Test func longLapseStillSurfacesLapsed() {
        let calendar = gregorian()
        // swiftlint:disable:next force_unwrapping
        let baseline = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        // swiftlint:disable:next force_unwrapping
        let monthLater = calendar.date(byAdding: .day, value: 30, to: baseline)!
        let rescue = StreakRescue.from(
            lastRecordedAt: baseline,
            priorStreak: 3,
            now: monthLater,
            calendar: calendar
        )
        #expect(rescue == .lapsed(priorStreak: 3))
    }
}
