import Foundation
import Testing
@testable import Services

/// Surface-level tests for `DailyTimeCoordinator`. The underlying
/// `SessionTimerService` actor is owned by ForgeKit (`ForgeAccessibility`)
/// — its lifecycle / cap behavior lives in ForgeKit's own suite. These
/// tests pin the coordinator's MainActor wrapper behaviors that MicrobeLab
/// is responsible for: cap mapping, init defaults, idempotent re-cap.
@Suite("DailyTimeCoordinator")
@MainActor
struct DailyTimeCoordinatorTests {
    @Test func defaultsActiveCapToThirty() {
        let coordinator = DailyTimeCoordinator()
        #expect(coordinator.activeCap == .thirty)
    }

    @Test func acceptsExplicitCapAtInit() {
        let coordinator = DailyTimeCoordinator(cap: .sixty)
        #expect(coordinator.activeCap == .sixty)
    }

    @Test func unlimitedCapIsAccepted() {
        let coordinator = DailyTimeCoordinator(cap: .unlimited)
        #expect(coordinator.activeCap == .unlimited)
    }

    @Test func updateCapIsIdempotentForSameValue() async {
        let coordinator = DailyTimeCoordinator(cap: .fortyFive)
        let originalCap = coordinator.activeCap
        await coordinator.updateCap(.fortyFive)
        #expect(coordinator.activeCap == originalCap)
    }

    @Test func updateCapSwapsCap() async {
        let coordinator = DailyTimeCoordinator(cap: .fifteen)
        await coordinator.updateCap(.sixty)
        #expect(coordinator.activeCap == .sixty)
    }
}
