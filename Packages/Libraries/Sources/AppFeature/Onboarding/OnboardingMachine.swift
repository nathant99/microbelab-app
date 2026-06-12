import Foundation

/// Top-level state machine for the first-time-experience flow per
/// `.claude/rules/state-machines.md` § `*Machine` Structs (Local View State).
///
/// Tracks `currentStep` so individual onboarding pages can refresh the mentor
/// + microscope-preview hero contextually. The companion `ForgeOnboardingFlow`
/// renders the actual UI; this struct exists so logic is testable without
/// SwiftUI host.
public nonisolated struct OnboardingMachine: Sendable, Equatable {
    /// Phase-1 5-step sequence per `Docs/FEATURE_PLAN.md` § Onboarding.
    public enum Step: Int, Sendable, CaseIterable, Comparable {
        case welcome = 0
        case microscopeIntro = 1
        case meetFirstMicrobe = 2
        case firstObservation = 3
        case firstQuiz = 4

        public static func < (lhs: Step, rhs: Step) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public var currentStep: Step
    public var hasCompletedFlow: Bool

    public init(currentStep: Step = .welcome, hasCompletedFlow: Bool = false) {
        self.currentStep = currentStep
        self.hasCompletedFlow = hasCompletedFlow
    }

    public var isFinalStep: Bool { currentStep == .firstQuiz }

    /// Advance to the next step or mark complete if we're at the final step.
    public mutating func advance() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        } else {
            hasCompletedFlow = true
        }
    }

    /// Skip the rest of onboarding. The parent gate already passed by the time
    /// the child sees this view; "Skip" lands at the same place as "Get Started".
    public mutating func skip() {
        hasCompletedFlow = true
    }

    public mutating func reset() {
        self = OnboardingMachine()
    }
}
