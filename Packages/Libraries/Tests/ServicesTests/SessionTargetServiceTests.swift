import Foundation
import Testing
@testable import Services

@Suite("SessionTargetMachine")
struct SessionTargetMachineTests {
    private func minutesAgo(_ minutes: Int) -> Date {
        Date.now.addingTimeInterval(TimeInterval(-minutes * 60))
    }

    @Test func newMachineStartsFocused() {
        let machine = SessionTargetMachine()
        #expect(machine.phase() == .focused)
        #expect(machine.hasShownGentleNudge == false)
        #expect(machine.elapsedMinutes() == 0)
    }

    @Test func phaseBoundaries() {
        let focused = SessionTargetMachine(startedAt: minutesAgo(5))
        #expect(focused.phase() == .focused)

        let inTargetLow = SessionTargetMachine(startedAt: minutesAgo(10))
        #expect(inTargetLow.phase() == .inTarget)

        let inTargetHigh = SessionTargetMachine(startedAt: minutesAgo(15))
        #expect(inTargetHigh.phase() == .inTarget)

        let overTarget = SessionTargetMachine(startedAt: minutesAgo(16))
        #expect(overTarget.phase() == .overTarget)
    }

    @Test func targetRangeMatchesForgeKitDefault() {
        // ForgeGamification.GamificationConfig.sessionTargetMinutes default
        // is `10...15` per ForgeKit docs. Lock that here so the rule doesn't
        // drift if the portfolio-wide default ever changes.
        #expect(SessionTargetMachine.targetRange == 10...15)
    }

    @Test func resetClearsState() {
        var machine = SessionTargetMachine(startedAt: minutesAgo(30), hasShownGentleNudge: true)
        machine.reset(startedAt: .now)
        #expect(machine.hasShownGentleNudge == false)
        #expect(machine.phase() == .focused)
    }

    @Test func markGentleNudgeShownIsIdempotent() {
        var machine = SessionTargetMachine()
        machine.markGentleNudgeShown()
        machine.markGentleNudgeShown()
        #expect(machine.hasShownGentleNudge == true)
    }

    @Test func focusedPhaseHasNoNudge() {
        let machine = SessionTargetMachine(startedAt: minutesAgo(5))
        #expect(machine.currentNudge() == .none)
    }

    @Test func inTargetPhaseFiresGentleNudgeOnce() {
        var machine = SessionTargetMachine(startedAt: minutesAgo(12))
        #expect(machine.currentNudge() == .gentleStretchSuggestion)
        machine.markGentleNudgeShown()
        #expect(machine.currentNudge() == .none)
    }

    @Test func overTargetPhaseAlwaysSuggestsPause() {
        var machine = SessionTargetMachine(startedAt: minutesAgo(22))
        #expect(machine.currentNudge() == .suggestPause)
        // Over-target nudge intentionally re-fires until the kid resets the
        // session — "remind, don't lecture" trumps the once-per-session rule
        // that gates the gentle in-target nudge.
        machine.markGentleNudgeShown()
        #expect(machine.currentNudge() == .suggestPause)
    }
}

@Suite("SessionTargetService")
@MainActor
struct SessionTargetServiceTests {
    @Test func serviceMirrorsMachine() {
        let service = SessionTargetService()
        #expect(service.phase == .focused)
        #expect(service.hasShownGentleNudge == false)
    }

    @Test func markGentleNudgeShownUpdatesMachine() {
        let service = SessionTargetService()
        service.markGentleNudgeShown()
        #expect(service.hasShownGentleNudge == true)
    }

    @Test func resetReplacesMachineStart() {
        let service = SessionTargetService(startedAt: Date.now.addingTimeInterval(-3600))
        service.markGentleNudgeShown()
        service.reset()
        #expect(service.hasShownGentleNudge == false)
        #expect(service.phase == .focused)
    }

    @Test func currentNudgeMirrorsMachineDerivation() {
        let focused = SessionTargetService()
        #expect(focused.currentNudge == .none)

        let inTarget = SessionTargetService(startedAt: Date.now.addingTimeInterval(-12 * 60))
        #expect(inTarget.currentNudge == .gentleStretchSuggestion)
        inTarget.markGentleNudgeShown()
        #expect(inTarget.currentNudge == .none)

        let overTarget = SessionTargetService(startedAt: Date.now.addingTimeInterval(-22 * 60))
        #expect(overTarget.currentNudge == .suggestPause)
    }
}
