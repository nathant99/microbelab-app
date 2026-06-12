import SwiftUI
import Services

/// Soft daily-cap overlay surfaced when the kid hits the parent-configured
/// daily-time cap (via `AppSettings.dailySessionCap`). Per
/// `.claude/rules/age-assurance.md` § Portfolio Status the wrap-up is
/// gentle — we never force-quit the app and never frame the cap as the
/// kid's failing. Trauma-safe register: praise the focus, suggest a stop.
///
/// The overlay shares the centered-card layout language of
/// `WelcomeBackOverlay` / `StreakRescueOverlay` so the cold-launch /
/// daily-cap / streak-rescue surfaces feel like one coherent quiet-friend
/// voice across the app.
///
/// Reduce-Transparency falls back to a solid card per
/// `Docs/FEATURE_PLAN.md` § Accessibility & Trauma-Informed Polish; the
/// host view supplies the resolved flag.
struct DailyCapOverlay: View {
    let dailyElapsedMinutes: Int
    let reduceTransparency: Bool
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Great session")
                .font(.headline)
            Text(verbatim: bodyCopy)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("See you next time", action: onAcknowledge)
                .buttonStyle(.glassProminent)
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(cardBackground)
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("DailyCapOverlay")
    }

    private var bodyCopy: String {
        if dailyElapsedMinutes <= 0 {
            return "Time to pause for today. The microbes will keep doing their thing."
        }
        return "You spent \(dailyElapsedMinutes) minutes exploring today — solid focus. The microbes will be here when you come back."
    }

    @ViewBuilder
    private var cardBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.primary.opacity(0.10))
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
        }
    }
}

#Preview("Standard") {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()
        DailyCapOverlay(dailyElapsedMinutes: 30, reduceTransparency: false, onAcknowledge: {})
    }
}

#Preview("Reduce Transparency") {
    ZStack {
        Color.gray.opacity(0.15).ignoresSafeArea()
        DailyCapOverlay(dailyElapsedMinutes: 45, reduceTransparency: true, onAcknowledge: {})
    }
}
