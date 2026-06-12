import SwiftUI
import Services

/// End-of-session summary sheet per `Docs/FEATURE_PLAN.md` § Parent
/// Integration → "Session closer". Renders a frozen `SessionSummary`
/// snapshot (warm headline + stats grid + next-session preview + dismiss
/// button) so the kid can wrap up intentionally instead of just
/// backgrounding the app.
///
/// **Trauma-informed framing** (per `.claude/rules/trauma-informed-content.md`):
/// the sheet never frames absence as failure. The "next time" preview is
/// a suggestion, not a streak threat. The dismiss CTA reads "See you
/// next time" so the act of closing the app is warm, not abrupt.
///
/// The summary is rendered as a `presentationDetents([.medium])` sheet so
/// the kid never feels trapped in a full-screen modal — they can always
/// scroll the tab content behind it.
struct SessionSummarySheet: View {
    let summary: SessionSummary
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            statsGrid
            previewCard
            Spacer(minLength: 4)
            Button(action: onDismiss) {
                Text("See you next time")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Closes the session summary")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("SessionSummarySheet")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.headline)
                .font(.title2.bold())
                .multilineTextAlignment(.leading)
            Text("A quick look at what you did today.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsGrid: some View {
        HStack(spacing: 14) {
            stat(label: "Level", value: "\(summary.currentLevel)")
            stat(label: "XP", value: "\(summary.totalXP)")
            stat(label: "Streak", value: "\(summary.currentStreak)d")
            stat(label: "Codex", value: "\(summary.microbesDiscovered)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Next time", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(summary.nextSessionPreview)
                .font(.callout)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(previewBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next time: \(summary.nextSessionPreview)")
    }

    @ViewBuilder
    private var previewBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.08))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Rich session") {
    SessionSummarySheet(
        summary: SessionSummary(
            currentLevel: 4,
            totalXP: 320,
            currentStreak: 6,
            microbesDiscovered: 7,
            achievementsEarned: 4
        ),
        onDismiss: {}
    )
}

#Preview("Quiet session") {
    SessionSummarySheet(
        summary: SessionSummary(
            currentLevel: 1,
            totalXP: 20,
            currentStreak: 0,
            microbesDiscovered: 0,
            achievementsEarned: 0
        ),
        onDismiss: {}
    )
}
