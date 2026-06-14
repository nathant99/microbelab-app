import SwiftUI
import Services

/// Welcome-back greeting for kids returning after a ≥ 3-day lapse per
/// `Docs/FEATURE_PLAN.md` § Engagement Foundation — "warm greeting + best-work
/// recap". The greeting + Continue affordance shipped in the initial release;
/// the optional `recap` parameter (added 2026-06-13 fifteenth-pass round)
/// closes the deferred "best-work recap" portion by rendering 1-2 previously-
/// met microbe display names below the greeting.
///
/// Trauma-informed copy per `.claude/rules/distributed-narrative.md` § Audience
/// register (ages 9-14, calm, no shame for absence). The microbiome metaphor
/// ("missed you") deliberately frames absence as wonder, not failure. When
/// the recap surface adds microbe names, the names are trauma-safely framed
/// as "still under the lens since you left" — never as "you abandoned them".
struct WelcomeBackOverlay: View {
    let daysAway: Int
    let reduceTransparency: Bool
    let recap: WelcomeBackRecap?
    let onContinue: () -> Void

    init(
        daysAway: Int,
        reduceTransparency: Bool = false,
        recap: WelcomeBackRecap? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.daysAway = daysAway
        self.reduceTransparency = reduceTransparency
        self.recap = recap
        self.onContinue = onContinue
    }

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

            if let recap, !recap.recalledMicrobeDisplayNames.isEmpty {
                recapCard(recap: recap)
            }

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
        .background(cardBackground)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("WelcomeBackOverlay")
    }

    /// Small inline card rendering the 1-2 recalled microbe display names.
    /// Lives inside the overlay's VStack so it inherits the same material
    /// background + a11y envelope rather than floating as a separate
    /// surface. Skipped when `recap.recalledMicrobeDisplayNames` is empty
    /// (the `if let` guard at the call site already handles that, but the
    /// inner check keeps the renderer defensive).
    @ViewBuilder
    private func recapCard(recap: WelcomeBackRecap) -> some View {
        VStack(spacing: 4) {
            Text(recap.leadInCopy)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(recap.recalledMicrobeDisplayNames.joined(separator: " · "))
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(reduceTransparency ? 0.10 : 0.06))
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recap.leadInCopy) \(recap.recalledMicrobeDisplayNames.joined(separator: ", "))")
    }

    @ViewBuilder
    private var cardBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.primary.opacity(0.10))
        } else {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        }
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

#Preview("Without recap") {
    WelcomeBackOverlay(daysAway: 4, onContinue: {})
}

#Preview("With recap") {
    WelcomeBackOverlay(
        daysAway: 4,
        recap: WelcomeBackRecap(
            recalledMicrobeDisplayNames: ["Lacto", "Yeast"],
            leadInCopy: "Still hanging around since you left:"
        ),
        onContinue: {}
    )
}
