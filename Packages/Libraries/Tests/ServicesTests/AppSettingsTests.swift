import Foundation
import Testing
@testable import Services

@Suite("AppSettings")
@MainActor
struct AppSettingsTests {
    // Per `.claude/rules/testing.md` § Crash-Resilience #5 — never use
    // UserDefaults.standard in tests; use a per-file suite + clear it.
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }

    @Test func defaultsAreTraumaSafe() {
        let settings = AppSettings.default
        #expect(settings.soundEffectsEnabled == true)
        #expect(settings.hapticsEnabled == true)
        #expect(settings.diseaseStoryGateEnabled == true)
        #expect(settings.dailySessionCap == .thirty)
    }

    @Test func storeRoundtripsSettings() {
        let defaults = makeDefaults()
        let store = AppSettingsStore(defaults: defaults, key: "test.settings")
        var next = store.settings
        next.soundEffectsEnabled = false
        next.dailySessionCap = .sixty
        store.save(next)

        let reopened = AppSettingsStore(defaults: defaults, key: "test.settings")
        #expect(reopened.settings.soundEffectsEnabled == false)
        #expect(reopened.settings.dailySessionCap == .sixty)
    }

    @Test func emptyStoreReturnsDefaults() {
        let defaults = makeDefaults()
        let store = AppSettingsStore(defaults: defaults, key: "test.empty")
        #expect(store.settings == AppSettings.default)
    }

    @Test func dailySessionCapMinutesMapping() {
        #expect(DailySessionCap.fifteen.minutes == 15)
        #expect(DailySessionCap.thirty.minutes == 30)
        #expect(DailySessionCap.unlimited.minutes == nil)
    }
}
