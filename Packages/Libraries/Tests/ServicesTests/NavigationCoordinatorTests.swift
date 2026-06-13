import Testing
import Foundation
import Models
@testable import Services

@MainActor
@Suite("NavigationCoordinator")
struct NavigationCoordinatorTests {

    @Test("Init defaults requestedTab to nil")
    func initDefaults() {
        let coordinator = NavigationCoordinator()
        #expect(coordinator.requestedTab == nil)
    }

    @Test("requestTab sets the requested tab")
    func requestTabSetsValue() {
        let coordinator = NavigationCoordinator()
        coordinator.requestTab(.codex)
        #expect(coordinator.requestedTab == .codex)
    }

    @Test("clearRequest sets requested tab to nil")
    func clearRequestResetsValue() {
        let coordinator = NavigationCoordinator()
        coordinator.requestTab(.microbiome)
        coordinator.clearRequest()
        #expect(coordinator.requestedTab == nil)
    }

    @Test("clearRequest is idempotent when already nil")
    func clearRequestIdempotent() {
        let coordinator = NavigationCoordinator()
        coordinator.clearRequest()
        coordinator.clearRequest()
        #expect(coordinator.requestedTab == nil)
    }

    @Test("requestTab overwrites a prior request")
    func requestTabOverwritesPrior() {
        let coordinator = NavigationCoordinator()
        coordinator.requestTab(.explore)
        coordinator.requestTab(.progress)
        #expect(coordinator.requestedTab == .progress)
    }

    @Test("All tab cases are requestable without crashing")
    func allTabsRequestable() {
        let coordinator = NavigationCoordinator()
        for tab in MicrobeLabTab.allCases {
            coordinator.requestTab(tab)
            #expect(coordinator.requestedTab == tab)
            coordinator.clearRequest()
            #expect(coordinator.requestedTab == nil)
        }
    }

    @Test("MicrobeLabTab raw values are stable slug strings")
    func tabRawValuesAreStable() {
        // Stable slug values matter — App Intents and analytics carry
        // them across launches. Renaming would silently drop existing
        // Shortcut wirings.
        #expect(MicrobeLabTab.explore.rawValue == "explore")
        #expect(MicrobeLabTab.codex.rawValue == "codex")
        #expect(MicrobeLabTab.microbiome.rawValue == "microbiome")
        #expect(MicrobeLabTab.progress.rawValue == "progress")
        #expect(MicrobeLabTab.profile.rawValue == "profile")
    }

    @Test("MicrobeLabTab Codable roundtrip preserves the case")
    func tabCodableRoundtrip() throws {
        for tab in MicrobeLabTab.allCases {
            let data = try JSONEncoder().encode(tab)
            let decoded = try JSONDecoder().decode(MicrobeLabTab.self, from: data)
            #expect(decoded == tab)
        }
    }

    @Test("Shared singleton survives instance comparisons")
    func sharedSingletonIsStable() {
        let first = NavigationCoordinator.shared
        let second = NavigationCoordinator.shared
        #expect(first === second)
    }
}
