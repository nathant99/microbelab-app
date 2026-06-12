import Foundation
import Testing
@testable import Services

@Suite("SessionCountStore")
@MainActor
struct SessionCountStoreTests {
    private func makeDefaults() -> UserDefaults {
        // swiftlint:disable:next force_unwrapping
        // Safety: deterministic suite name per #file; never nil under XCTest.
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }

    @Test func freshStoreStartsAtZero() {
        let defaults = makeDefaults()
        let store = SessionCountStore(defaults: defaults, key: "test.sessions.fresh")
        #expect(store.sessionCount == 0)
    }

    @Test func incrementPersistsAcrossInstances() {
        let defaults = makeDefaults()
        let key = "test.sessions.persist"

        let first = SessionCountStore(defaults: defaults, key: key)
        first.incrementForSessionStart()
        first.incrementForSessionStart()
        first.incrementForSessionStart()
        #expect(first.sessionCount == 3)

        let reopened = SessionCountStore(defaults: defaults, key: key)
        #expect(reopened.sessionCount == 3)
    }

    @Test func clearResetsToZero() {
        let defaults = makeDefaults()
        let store = SessionCountStore(defaults: defaults, key: "test.sessions.clear")
        store.incrementForSessionStart()
        store.incrementForSessionStart()
        store.clear()
        #expect(store.sessionCount == 0)
    }
}

@Suite("TabDisclosure")
struct TabDisclosureTests {
    @Test func session1HidesEverythingPastCodex() {
        let disclosure = TabDisclosure.from(sessionCount: 1)
        #expect(disclosure == .session1)
        #expect(disclosure.showsMicrobiome == false)
        #expect(disclosure.showsProgress == false)
        #expect(disclosure.showsProfile == false)
    }

    @Test func zeroCountTreatedAsSession1() {
        // Pre-onboarding edge case: SessionCountStore starts at 0; the kid
        // shouldn't see anything past Codex even if increment hasn't fired.
        let disclosure = TabDisclosure.from(sessionCount: 0)
        #expect(disclosure == .session1)
        #expect(disclosure.showsMicrobiome == false)
    }

    @Test func session2RevealsMicrobiome() {
        let disclosure = TabDisclosure.from(sessionCount: 2)
        #expect(disclosure == .session2to3)
        #expect(disclosure.showsMicrobiome == true)
        #expect(disclosure.showsProgress == false)
        #expect(disclosure.showsProfile == false)
    }

    @Test func session3StaysInMidBand() {
        let disclosure = TabDisclosure.from(sessionCount: 3)
        #expect(disclosure == .session2to3)
        #expect(disclosure.showsMicrobiome == true)
        #expect(disclosure.showsProgress == false)
    }

    @Test func session4RevealsFullChrome() {
        let disclosure = TabDisclosure.from(sessionCount: 4)
        #expect(disclosure == .fullDisclosure)
        #expect(disclosure.showsMicrobiome == true)
        #expect(disclosure.showsProgress == true)
        #expect(disclosure.showsProfile == true)
    }

    @Test func highSessionCountStaysFullDisclosure() {
        let disclosure = TabDisclosure.from(sessionCount: 200)
        #expect(disclosure == .fullDisclosure)
    }
}
