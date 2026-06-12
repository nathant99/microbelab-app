import SwiftUI
import Services

/// Pin-style overlay surfacing the gentle in-target nudge + the softer
/// over-target pause suggestion per `Docs/FEATURE_PLAN.md` § Engagement
/// Foundation → "Session targeting".
///
/// Trauma-informed copy per the COVID-sensitive register: praise focus
/// instead of timing the kid, frame the over-target nudge as "the microbes
/// will be here when you come back" not "you've been on too long".
///
/// Periodic refresh uses SwiftUI's `TimelineView(.periodic(...))` so the
/// service stays pure (no internal timer). The view re-evaluates the
/// service's derived `currentNudge` every 30 s.
struct SessionNudgeOverlay: View {
    let service: SessionTargetService
    let reduceMotion: Bool
    let reduceTransparency: Bool

    init(
        service: SessionTargetService,
        reduceMotion: Bool = false,
        reduceTransparency: Bool = false
    ) {
        self.service = service
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
    }

    var body: some View {
        // 30 s refresh keeps the view responsive without burning energy on
        // 1 Hz wakeups for a banner the kid usually won't see anyway.
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            switch service.currentNudge {
            case .none:
                EmptyView()
            case .gentleStretchSuggestion:
                gentleBanner
                    .transition(nudgeTransition)
            case .suggestPause:
                pauseBanner
                    .transition(nudgeTransition)
            }
        }
        .animation(nudgeAnimation, value: service.currentNudge)
    }

    /// Reduce-Motion drops the slide-from-top morph (vestibular trigger);
    /// opacity still cross-fades so the kid sees the banner change.
    private var nudgeTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity)
    }

    /// Reduce-Motion replaces the spring-y easeInOut with an instant
    /// transition (animation collapses to zero duration).
    private var nudgeAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.25)
    }

    private var gentleBanner: some View {
        nudgeCard(
            systemImage: "figure.mind.and.body",
            title: "Nice focus",
            body: "You've been exploring for a bit. Quick stretch?",
            primaryLabel: "Keep exploring",
            onPrimary: dismissGentle,
            secondaryLabel: "Got it",
            onSecondary: dismissGentle
        )
        .accessibilityIdentifier("SessionNudge.Gentle")
    }

    private var pauseBanner: some View {
        nudgeCard(
            systemImage: "leaf.fill",
            title: "Wide world out there",
            body: "The microbes will be here next time. Easy to step away.",
            primaryLabel: "One more minute",
            onPrimary: dismissGentle,
            secondaryLabel: "Pause",
            onSecondary: dismissGentle
        )
        .accessibilityIdentifier("SessionNudge.Pause")
    }

    private func nudgeCard(
        systemImage: String,
        title: String,
        body: String,
        primaryLabel: String,
        onPrimary: @escaping () -> Void,
        secondaryLabel: String,
        onSecondary: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 12) {
                Spacer()
                Button(secondaryLabel, action: onSecondary)
                    .buttonStyle(.glass)
                    .controlSize(.small)
                    .accessibilityHint("Dismisses the session nudge")
                Button(primaryLabel, action: onPrimary)
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
                    .accessibilityHint("Keeps the current session going")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .padding(.horizontal)
        .padding(.top, 4)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.10))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
    }

    private func dismissGentle() {
        service.markGentleNudgeShown()
    }
}

#Preview("Gentle") {
    SessionNudgeOverlay(service: SessionTargetService(startedAt: .now.addingTimeInterval(-11 * 60)))
}

#Preview("Pause") {
    SessionNudgeOverlay(service: SessionTargetService(startedAt: .now.addingTimeInterval(-20 * 60)))
}
