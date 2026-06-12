import SwiftUI

/// Welcome-back greeting for kids returning after a ≥ 3-day lapse per
/// `Docs/FEATURE_PLAN.md` § Engagement Foundation — "warm greeting + best-work
/// recap". Recap is left to a follow-up PR; v1 is the warm greeting + Continue
/// affordance.
///
/// Trauma-informed copy per `.claude/rules/distributed-narrative.md` § Audience
/// register (ages 9-14, calm, no shame for absence). The microbiome metaphor
/// ("missed you") deliberately frames absence as wonder, not failure.
struct WelcomeBackOverlay: View {
    let daysAway: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Welcome back")
                .font(.title2.bold())

            Text(welcomeBodyCopy)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onContinue) {
                Text("Let's explore")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .accessibilityHint("Dismisses the welcome back card")
        }
        .padding(.vertical, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("WelcomeBackOverlay")
    }

    private var welcomeBodyCopy: String {
        if daysAway <= 7 {
            return "It's been \(daysAway) days. The microbiome was curious about you."
        }
        if daysAway <= 30 {
            return "It's been a few weeks. Microbes have been busy — let's see what's changed."
        }
        return "It's been a while. The microscope is still warm. Ready when you are."
    }
}

#Preview {
    WelcomeBackOverlay(daysAway: 4, onContinue: {})
}
