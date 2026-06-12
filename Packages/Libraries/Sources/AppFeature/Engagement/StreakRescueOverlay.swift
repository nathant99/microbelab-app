import SwiftUI
import Services

/// Warm broken-streak surface per `Docs/FEATURE_PLAN.md` § Engagement
/// Foundation → "warm broken-streak messaging ('The microbiome missed you!')".
///
/// Surfaces only when `StreakRescue.lapsed(priorStreak:)` is non-`.none` on
/// cold launch — distinct from `WelcomeBackOverlay`, which fires on absolute
/// calendar days regardless of streak state. The two overlays are mutually
/// exclusive at the AppRootView wiring level so the kid never sees both.
///
/// Trauma-informed copy per the COVID-sensitive register: name the absence
/// without shame, acknowledge the prior achievement, frame return as choice.
struct StreakRescueOverlay: View {
    let priorStreak: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("The microbiome missed you")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(bodyCopy)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onContinue) {
                Text("Pick up where we left off")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .accessibilityHint("Dismisses the streak rescue card and opens the app")
        }
        .padding(.vertical, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("StreakRescueOverlay")
    }

    private var bodyCopy: String {
        if priorStreak >= 14 {
            return "You had a \(priorStreak)-day streak. Time to grow a new one — no pressure."
        }
        if priorStreak >= 5 {
            return "You had a \(priorStreak)-day streak. Start a new one whenever you're ready."
        }
        return "Microbes don't keep score. Glad you came back."
    }
}

#Preview("Long streak") {
    StreakRescueOverlay(priorStreak: 21, onContinue: {})
}

#Preview("Short streak") {
    StreakRescueOverlay(priorStreak: 3, onContinue: {})
}
