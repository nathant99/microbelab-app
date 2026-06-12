import SwiftUI
import Services
import SharedUI
import ForgeUI

/// 5-step first-time experience per `Docs/FEATURE_PLAN.md` § Onboarding +
/// `Docs/TECHNICAL_DESIGN.md` § Onboarding & First-Time Experience.
///
/// Aha moment: by step 3 ("meet first microbe") the kid sees Lacto introduce
/// themselves as "one of trillions of tiny lives that help you digest food".
/// Total to aha is ≤ 60 seconds via the Next button cadence.
///
/// Wraps `ForgeOnboardingFlow` per `.claude/rules/forgekit.md` § ForgeUI Quick
/// Reference. Pages use SF Symbol heroes; portrait pack is asset-blocked per
/// FEATURE_PLAN.
public struct MicrobeLabOnboardingFlow: View {
    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ForgeOnboardingFlow(pages: Self.pages, onComplete: onComplete)
            .accessibilityIdentifier("MicrobeLabOnboardingFlow")
            .onAppear {
                DebugLog.lifecycle("MicrobeLabOnboardingFlow onAppear")
            }
    }

    /// 5 onboarding pages — see `OnboardingMachine.Step` for the canonical
    /// sequence. Body copy stays kid-readable (age 9-14 register) per
    /// `.claude/rules/distributed-narrative.md` § Audience register.
    static let pages: [ForgeOnboardingFlow.Page] = [
        .init(
            title: "Welcome to MicrobeLab",
            body: "Microbes are everywhere — even helping you right now. Let's go meet a few.",
            imageName: "sparkles"
        ),
        .init(
            title: "Pinch to Zoom In",
            body: "Your microscope can zoom from your skin all the way down to a single cell. Pinch out, pinch in — see what's hiding.",
            imageName: "magnifyingglass.circle"
        ),
        .init(
            title: "Meet a Microbe",
            body: "Lacto is one of trillions of tiny lives that help you digest food. Most microbes aren't germs — most are quiet helpers.",
            imageName: "person.circle.fill"
        ),
        .init(
            title: "Try the Microbiome",
            body: "Feed the gut fiber, balanced meals, or sugar — and watch which microbes grow. There's no wrong choice; we're just exploring.",
            imageName: "leaf.circle"
        ),
        .init(
            title: "Test Your Curiosity",
            body: "Each question kit has 5 quick questions. Get one wrong? No big deal. The microbiome is curious about you too.",
            imageName: "checkmark.seal"
        ),
    ]
}
