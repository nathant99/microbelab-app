import Foundation

/// State machine for the 30-second parent handoff per `Docs/FEATURE_PLAN.md`
/// § Onboarding & Child Safety. Pure value type — testable without a SwiftUI
/// host per `.claude/rules/state-machines.md` § `*Machine` Structs.
///
/// The handoff captures preferences a grown-up should set BEFORE the kid
/// drives the device: disease-story comfort + daily session cap. Both lift to
/// `AppSettings` so the Settings tab remains the single source of truth. The
/// machine carries the in-flight choices through the step sequence; the host
/// view writes them into `AppSettingsStore` when the parent taps "Ready" on
/// the final step.
public nonisolated struct ParentHandoffMachine: Sendable, Equatable {
    /// 3-step parent setup. Each step is a single screen with clear choices.
    /// Keeps the total flow under 30 seconds by design.
    public enum Step: Int, Sendable, CaseIterable, Comparable {
        /// Welcome + framing — "30 seconds to set things up".
        case welcome = 0
        /// Content comfort — disease-story arcs opt-in or default-off.
        case contentComfort = 1
        /// Daily session cap — picker; default 30 minutes per portfolio.
        case sessionCap = 2
        /// Ready confirmation — "Hand the device to your kid".
        case ready = 3

        public static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public var currentStep: Step
    /// Whether the parent has opted IN to disease-story arcs. Default false
    /// keeps the gate ON (sensitive content stays opt-in per
    /// `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture).
    public var allowsDiseaseStories: Bool
    /// Daily session cap selection. Initialized to the portfolio default per
    /// `.claude/rules/age-assurance.md`.
    public var dailyCapChoice: ParentDailyCap
    public var hasCompletedHandoff: Bool

    public init(
        currentStep: Step = .welcome,
        allowsDiseaseStories: Bool = false,
        dailyCapChoice: ParentDailyCap = .thirtyMinutes,
        hasCompletedHandoff: Bool = false
    ) {
        self.currentStep = currentStep
        self.allowsDiseaseStories = allowsDiseaseStories
        self.dailyCapChoice = dailyCapChoice
        self.hasCompletedHandoff = hasCompletedHandoff
    }

    public var isFinalStep: Bool { currentStep == .ready }

    public mutating func advance() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        } else {
            hasCompletedHandoff = true
        }
    }

    /// Skip from any step to completion without altering preferences. Used
    /// when the grown-up taps the "Skip — I'll set this later" affordance.
    public mutating func skip() {
        hasCompletedHandoff = true
    }

    public mutating func reset() {
        self = ParentHandoffMachine()
    }
}

/// View-layer daily cap enum that mirrors the portfolio choices in
/// `Services.DailySessionCap` without importing the Services module from a
/// pure-value state machine. The host view maps these to the canonical
/// `DailySessionCap` cases when persisting.
public nonisolated enum ParentDailyCap: String, Sendable, CaseIterable, Identifiable {
    case fifteenMinutes
    case thirtyMinutes
    case fortyFiveMinutes
    case sixtyMinutes
    case unlimited

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .fortyFiveMinutes: return "45 minutes"
        case .sixtyMinutes: return "60 minutes"
        case .unlimited: return "No limit"
        }
    }
}
