import SwiftUI
import Models
import Services

/// Phase 4 global-microbiome tour view layer. Consumer for
/// `GlobalMicrobiomeTourService` (PR #162) + `ProgressionService.global-
/// microbiome-tour` gate (PR #137).
///
/// Closes the consumer-wiring half of `Docs/FEATURE_PLAN.md` Phase 4 line
/// 177. Surfaces the four canonical stops (Yellowstone hot spring → deep-sea
/// vent → human gut → soil underground) per the `StopPresentation` switch:
///
/// - `.ready` — reviewer-signed-off prose; render stop body (when prose
///   lands in a focused future round)
/// - `.authoringPending` — render "Coming soon" affordance per ADR-016
/// - `.gatedBehindProgression` — render the trauma-informed unlock-hint
///   copy from `ProgressionService.unlockHint(for:)`
///
/// **Cultural-respect gate** (per `.claude/rules/distributed-narrative.md`
/// § cultural-sensitivity gates): the Yellowstone primitive descriptor
/// explicitly surfaces "Indigenous TEK" as a curriculum hook even at the
/// metadata tier. The view forwards the primitive string verbatim so the
/// credit surface is visible at every authoring state (`.placeholder` /
/// `.draftAwaitingReview` / `.reviewerSignedOff`).
///
/// **Trauma-informed posture**: per-stop framing reuses the canonical
/// catalog title + primitive without authoring any prose; the view layer
/// stays scaffold-only until the per-stop reviewer-signed-off prose
/// lands. No SAMHSA register weight crossed by the structural surface.
public struct GlobalMicrobiomeTourView: View {
    private let tour: GlobalMicrobiomeTourService
    private let progression: ProgressionService?
    private let catalog: MicrobeCatalogService?

    public init(
        tour: GlobalMicrobiomeTourService,
        progression: ProgressionService? = nil,
        catalog: MicrobeCatalogService? = nil
    ) {
        self.tour = tour
        self.progression = progression
        self.catalog = catalog
    }

    public var body: some View {
        List {
            Section {
                Text("Microbiomes show up in places you wouldn't expect — hot springs, deep-sea vents, your own gut, the quiet underground. Each stop teaches a different ecology primitive.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            ForEach(tour.catalog) { record in
                stopRow(for: record)
            }

            // Footer credit per `.claude/rules/distributed-narrative.md`
            // § cultural-sensitivity gates. Surfaces even at placeholder
            // tier so the credit doesn't appear only when prose lands.
            Section {
                Text("Yellowstone sits on land with deep Indigenous history. Traditional Ecological Knowledge of these ecosystems predates Western microbiology by generations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Global tour")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("GlobalMicrobiomeTourView")
    }

    @ViewBuilder
    private func stopRow(for record: GlobalMicrobiomeTourStopRecord) -> some View {
        let gateOpen = progression?.isUnlocked(record.gateID) ?? false
        let presentation = tour.presentation(for: record, gateOpen: gateOpen)

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.displayTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                statusBadge(for: presentation)
            }
            Text(record.primitive)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            featuredMicrobeRow(for: record)
            bodyCopy(for: presentation)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: record, presentation: presentation))
    }

    @ViewBuilder
    private func statusBadge(for presentation: GlobalMicrobiomeTourService.StopPresentation) -> some View {
        switch presentation {
        case .ready:
            Label("Ready", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .labelStyle(.titleAndIcon)
        case .authoringPending:
            Label("Coming soon", systemImage: "hourglass")
                .font(.caption)
                .foregroundStyle(.orange)
                .labelStyle(.titleAndIcon)
        case .gatedBehindProgression:
            Label("Locked", systemImage: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
        }
    }

    /// Surface up to three featured-microbe display names per stop. Falls
    /// back to the slug when the catalog isn't injected (test environment
    /// or pre-bootstrap render).
    @ViewBuilder
    private func featuredMicrobeRow(for record: GlobalMicrobiomeTourStopRecord) -> some View {
        let names = featuredDisplayNames(for: record)
        if !names.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "circle.hexagongrid")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Featured: \(names.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func bodyCopy(for presentation: GlobalMicrobiomeTourService.StopPresentation) -> some View {
        switch presentation {
        case .ready:
            Text("Tap to begin")
                .font(.callout)
                .foregroundStyle(.tint)
        case .authoringPending:
            Text("This stop is coming soon — we're reviewing the content together.")
                .font(.callout)
                .foregroundStyle(.secondary)
        case let .gatedBehindProgression(record):
            let hint = progression?.unlockHint(for: record.gateID)
                ?? "Keep exploring — this stop opens after a few more sessions."
            Text(hint)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func featuredDisplayNames(for record: GlobalMicrobiomeTourStopRecord) -> [String] {
        guard let catalog else {
            return record.featuredMicrobeSlugs
        }
        return record.featuredMicrobeSlugs.compactMap { slug in
            catalog.microbes.first(where: { $0.slug == slug })?.displayName
        }
    }

    private func accessibilityLabel(
        for record: GlobalMicrobiomeTourStopRecord,
        presentation: GlobalMicrobiomeTourService.StopPresentation
    ) -> String {
        let statusFragment: String
        switch presentation {
        case .ready:                  statusFragment = "Ready"
        case .authoringPending:       statusFragment = "Coming soon"
        case .gatedBehindProgression: statusFragment = "Locked"
        }
        return "\(record.displayTitle). \(record.primitive). Status: \(statusFragment)."
    }
}
