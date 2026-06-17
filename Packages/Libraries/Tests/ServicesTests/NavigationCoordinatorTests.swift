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

    // MARK: - Phase 3 / Phase 4 deep-link sub-surface routing

    @Test("Init defaults requestedSubSurface to nil")
    func initDefaultsSubSurface() {
        let coordinator = NavigationCoordinator()
        #expect(coordinator.requestedSubSurface == nil)
    }

    @Test("requestSubSurface sets both the sub-surface and the host tab")
    func requestSubSurfaceImpliesHostTab() {
        // Per Models/MicrobeLabSubSurface.hostTab: every canonical Phase 3
        // / Phase 4 sub-surface lives behind the Microbiome tab. The
        // coordinator MUST set requestedTab = .microbiome AND
        // requestedSubSurface = surface so AppRootView + MicrobiomeView
        // both observe the right slot in one update cycle.
        let coordinator = NavigationCoordinator()
        coordinator.requestSubSurface(.diseaseStories)
        #expect(coordinator.requestedSubSurface == .diseaseStories)
        #expect(coordinator.requestedTab == .microbiome)
    }

    @Test("All sub-surface cases route to the Microbiome tab")
    func allSubSurfacesRouteToMicrobiome() {
        let coordinator = NavigationCoordinator()
        for surface in MicrobeLabSubSurface.allCases {
            coordinator.requestSubSurface(surface)
            #expect(coordinator.requestedSubSurface == surface)
            #expect(coordinator.requestedTab == surface.hostTab)
        }
    }

    @Test("clearSubSurfaceRequest clears only the sub-surface, not the tab")
    func clearSubSurfaceLeavesTab() {
        // The two-step clearing is intentional: AppRootView clears the
        // tab as soon as the tab switch lands, but MicrobiomeView needs
        // the sub-surface field to survive at least until its own
        // .onChange observer fires. Clearing one MUST NOT clear the other.
        let coordinator = NavigationCoordinator()
        coordinator.requestSubSurface(.vaccineExplainer)
        coordinator.clearSubSurfaceRequest()
        #expect(coordinator.requestedSubSurface == nil)
        #expect(coordinator.requestedTab == .microbiome)
    }

    @Test("clearRequest clears only the tab, not the sub-surface")
    func clearTabLeavesSubSurface() {
        let coordinator = NavigationCoordinator()
        coordinator.requestSubSurface(.historicalContext)
        coordinator.clearRequest()
        #expect(coordinator.requestedTab == nil)
        #expect(coordinator.requestedSubSurface == .historicalContext)
    }

    @Test("clearSubSurfaceRequest is idempotent when already nil")
    func clearSubSurfaceIdempotent() {
        let coordinator = NavigationCoordinator()
        coordinator.clearSubSurfaceRequest()
        coordinator.clearSubSurfaceRequest()
        #expect(coordinator.requestedSubSurface == nil)
    }

    @Test("requestSubSurface overwrites a prior sub-surface request")
    func requestSubSurfaceOverwritesPrior() {
        let coordinator = NavigationCoordinator()
        coordinator.requestSubSurface(.diseaseStories)
        coordinator.requestSubSurface(.globalMicrobiomeTour)
        #expect(coordinator.requestedSubSurface == .globalMicrobiomeTour)
        #expect(coordinator.requestedTab == .microbiome)
    }
}
