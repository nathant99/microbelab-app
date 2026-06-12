import Foundation
import Observation

/// View-local state machine for the 10-15 minute session target per
/// `Docs/TECHNICAL_DESIGN.md` § Engagement & Retention + `Docs/FEATURE_PLAN.md`
/// § Engagement Foundation. Pure value type; the companion `SessionTargetService`
/// holds the live `@Observable` surface.
///
/// Convention: "in-target" is the 10-15 min window where a gentle ending nudge
/// is offered. Below 10 min, the kid is still in flow — no nudge.
/// Above 15 min, we surface a more visible suggest-pause cue.
public nonisolated struct SessionTargetMachine: Sendable, Equatable {
    public enum Phase: Sendable, Equatable {
        case focused
        case inTarget
        case overTarget
    }

    /// Portfolio-canonical target window per `ForgeGamification.GamificationConfig.sessionTargetMinutes`.
    public static let targetRange: ClosedRange<Int> = 10...15

    public var startedAt: Date
    public var hasShownGentleNudge: Bool

    public init(startedAt: Date = .now, hasShownGentleNudge: Bool = false) {
        self.startedAt = startedAt
        self.hasShownGentleNudge = hasShownGentleNudge
    }

    public func elapsedMinutes(now: Date = .now) -> Int {
        max(0, Int(now.timeIntervalSince(startedAt) / 60))
    }

    public func phase(now: Date = .now) -> Phase {
        let minutes = elapsedMinutes(now: now)
        if minutes < Self.targetRange.lowerBound { return .focused }
        if minutes <= Self.targetRange.upperBound { return .inTarget }
        return .overTarget
    }

    public mutating func markGentleNudgeShown() {
        hasShownGentleNudge = true
    }

    public mutating func reset(startedAt: Date = .now) {
        self = SessionTargetMachine(startedAt: startedAt)
    }
}

/// `@Observable` facade SwiftUI can read. Holds the machine + injectable time
/// source for tests. View code calls `phase` / `elapsedMinutes` on the
/// observable surface to drive nudges without poking the machine directly.
///
/// Per `.claude/rules/workflow.md` § Service Architecture: construct once at
/// app boot; pass through the view hierarchy as a parameter, NOT a singleton.
@MainActor
@Observable
public final class SessionTargetService {
    public private(set) var machine: SessionTargetMachine

    public init(startedAt: Date = .now) {
        self.machine = SessionTargetMachine(startedAt: startedAt)
    }

    public var elapsedMinutes: Int {
        machine.elapsedMinutes()
    }

    public var phase: SessionTargetMachine.Phase {
        machine.phase()
    }

    public var hasShownGentleNudge: Bool {
        machine.hasShownGentleNudge
    }

    public func markGentleNudgeShown() {
        machine.markGentleNudgeShown()
        DebugLog.state("SessionTargetService — gentle nudge shown")
    }

    public func reset(startedAt: Date = .now) {
        machine.reset(startedAt: startedAt)
        DebugLog.state("SessionTargetService — reset to \(startedAt)")
    }
}
