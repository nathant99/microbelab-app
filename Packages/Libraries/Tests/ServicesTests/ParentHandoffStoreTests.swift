import Foundation
import Testing
@testable import Services

@Suite("ParentHandoffStore")
@MainActor
struct ParentHandoffStoreTests {
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
        let store = ParentHandoffStore(defaults: defaults, key: "test.parenthandoff.empty")
        #expect(store.hasCompletedHandoff == false)
    }

    @Test func markingCompletedPersistsAcrossInits() {
        let defaults = makeDefaults()
        let store = ParentHandoffStore(defaults: defaults, key: "test.parenthandoff.persist")
        store.markCompleted()
        #expect(store.hasCompletedHandoff == true)

        let reopened = ParentHandoffStore(defaults: defaults, key: "test.parenthandoff.persist")
        #expect(reopened.hasCompletedHandoff == true)
    }

    @Test func resetClearsFlag() {
        let defaults = makeDefaults()
        let store = ParentHandoffStore(defaults: defaults, key: "test.parenthandoff.reset")
        store.markCompleted()
        store.reset()
        #expect(store.hasCompletedHandoff == false)

        let reopened = ParentHandoffStore(defaults: defaults, key: "test.parenthandoff.reset")
        #expect(reopened.hasCompletedHandoff == false)
    }
}
