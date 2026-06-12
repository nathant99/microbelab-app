import Foundation
import Testing
@testable import Services

@Suite("OnboardingStore")
@MainActor
struct OnboardingStoreTests {
    // Per `.claude/rules/testing.md` § Crash-Resilience #5 — never
    // UserDefaults.standard in tests; per-file suite.
    private func makeDefaults() -> UserDefaults {
        // swiftlint:disable:next force_unwrapping
        // Safety: deterministic suite name per #file; never nil under XCTest.
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }

    @Test func emptyStoreReportsIncomplete() {
        let defaults = makeDefaults()
        let store = OnboardingStore(defaults: defaults, key: "test.onboarding.empty")
        #expect(store.hasCompletedOnboarding == false)
    }

    @Test func markingCompletedPersistsAcrossInits() {
        let defaults = makeDefaults()
        let store = OnboardingStore(defaults: defaults, key: "test.onboarding.persist")
        store.markCompleted()
        #expect(store.hasCompletedOnboarding == true)

        let reopened = OnboardingStore(defaults: defaults, key: "test.onboarding.persist")
        #expect(reopened.hasCompletedOnboarding == true)
    }

    @Test func resetClearsFlag() {
        let defaults = makeDefaults()
        let store = OnboardingStore(defaults: defaults, key: "test.onboarding.reset")
        store.markCompleted()
        store.reset()
        #expect(store.hasCompletedOnboarding == false)

        let reopened = OnboardingStore(defaults: defaults, key: "test.onboarding.reset")
        #expect(reopened.hasCompletedOnboarding == false)
    }
}
