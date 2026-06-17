import SwiftUI
import Models
import Services

/// Consumer view for the Phase 3 disease-story arc catalog. Renders one row
/// per `DiseaseStoryArcRecord` and surfaces the right affordance per
/// `DiseaseStoryService.ArcPresentation`:
///
/// - **`.ready`** — reviewer-signed-off prose body. The view currently
///   renders a placeholder body row (`bodyPlaceholder`) because no arc has
///   shipped reviewer-signoff yet per ADR-016. When the reviewer pathway
///   surfaces signed-off prose, the `.ready` branch swaps to render the
///   real body. The structural surface lands NOW so the kid path is
///   complete the moment prose arrives.
/// - **`.authoringPending`** — gate + consent are clear, but the arc body
///   is still `.placeholder` / `.draftAwaitingReview`. Renders the warm
///   "Coming soon" affordance per the trauma-informed register.
/// - **`.gatedBehindProgression`** — gate isn't open yet. Renders the
///   ProgressionService unlock-hint (already stoplist-pinned by
///   ProgressionService tests; copy never reads as failure).
/// - **`.gatedBehindConsent`** — parent has not opted into disease-story
///   arcs. Renders a parent-handoff affordance pointing at the Settings
///   "For parents" surface (the `ParentalConsentManagerView`).
///
/// **Trauma-informed posture** (load-bearing per `.claude/rules/trauma-informed-content.md`):
/// every copy string the view renders avoids warfare / shame / threat /
/// fear-induction lexicon. The view's tests pin a parameterized stoplist
/// at unit-test time so a future copy edit can't regress the property.
///
/// **Reachability**: this view is intentionally only reachable via the
/// `MicrobiomeView` toolbar when the `diseaseStory:` parameter is non-nil.
/// AppRootView wires the canonical service through. Per-arc deep-link
/// flows land in a future round when the `.ready` body content lands.
public struct DiseaseStoryArcView: View {
    let diseaseStory: DiseaseStoryService
    let progression: ProgressionService?
    let consent: ParentalConsentService?

    public init(
        diseaseStory: DiseaseStoryService,
        progression: ProgressionService? = nil,
        consent: ParentalConsentService? = nil
    ) {
        self.diseaseStory = diseaseStory
        self.progression = progression
        self.consent = consent
    }

    public var body: some View {
        List {
            Section {
                Text(verbatim: introCopy)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 4)
            } header: {
                Text("About these stories")
            } footer: {
                Text(verbatim: "Stories ship one at a time after a reviewer signs off on the trauma-informed register. You'll see new arcs appear here when they're ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(diseaseStory.catalog) { record in
                    arcRow(for: record)
                }
            } header: {
                Text("Story arcs")
            }
        }
        .navigationTitle("Disease stories")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var introCopy: String {
        // Trauma-informed intro: names the why (curiosity + understanding) +
        // names the kid's agency (skip is always allowed) + names the parent
        // role (opt-in). Stays warm; does NOT promise specific content.
        "Sometimes microbes and bodies meet in ways that take time to heal. These stories show how communities help each other when that happens. Skipping is always allowed, and a grown-up turns these stories on with you."
    }

    @ViewBuilder
    private func arcRow(for record: DiseaseStoryArcRecord) -> some View {
        let gateOpen = progression?.isUnlocked(record.gateID) ?? false
        let parentConsented = consent?.hasValidConsent(for: .diseaseStoryArcs) ?? false
        let presentation = diseaseStory.presentation(
            for: record,
            gateOpen: gateOpen,
            parentConsented: parentConsented
        )
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verbatim: record.displayTitle)
                    .font(.headline)
                Spacer()
                statusChip(for: presentation)
            }
            Text(verbatim: record.primitive)
                .font(.caption)
                .foregroundStyle(.secondary)
            presentationBody(for: presentation, record: record)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: presentation, record: record))
    }

    @ViewBuilder
    private func presentationBody(
        for presentation: DiseaseStoryService.ArcPresentation,
        record: DiseaseStoryArcRecord
    ) -> some View {
        switch presentation {
        case .ready:
            // Reviewer-signoff has landed; the structural body renders a
            // placeholder line until per-arc prose ships in a focused round
            // (per ADR-016). When prose arrives, swap this for the rendered
            // body content.
            Text(verbatim: "Story ready. Tap the arc to read.")
                .foregroundStyle(.secondary)
        case .authoringPending:
            Text(verbatim: "Coming soon — a reviewer is reading this story now.")
                .foregroundStyle(.secondary)
        case .gatedBehindProgression:
            // Trauma-informed: the unlock-hint copy never reads as failure
            // — ProgressionService.unlockHint already runs through a stoplist
            // test. We surface the canonical unlock hint when available; the
            // canonical fallback is the per-arc default copy.
            if let hint = progression?.unlockHint(for: record.gateID) {
                Text(verbatim: hint)
                    .foregroundStyle(.secondary)
            } else {
                Text(verbatim: "Play across a few more days to meet this story.")
                    .foregroundStyle(.secondary)
            }
        case .gatedBehindConsent:
            Text(verbatim: "A grown-up turns these stories on in Settings — under \"For parents.\"")
                .foregroundStyle(.secondary)
        }
    }

    private func statusChip(for presentation: DiseaseStoryService.ArcPresentation) -> some View {
        let (label, systemImage): (String, String)
        switch presentation {
        case .ready:
            label = "Ready"
            systemImage = "book.fill"
        case .authoringPending:
            label = "Coming soon"
            systemImage = "hourglass"
        case .gatedBehindProgression:
            label = "Keep exploring"
            systemImage = "leaf"
        case .gatedBehindConsent:
            label = "Ask a grown-up"
            systemImage = "person.2.fill"
        }
        return Label(label, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }

    private func accessibilityLabel(
        for presentation: DiseaseStoryService.ArcPresentation,
        record: DiseaseStoryArcRecord
    ) -> String {
        let statusPhrase: String
        switch presentation {
        case .ready:
            statusPhrase = "ready"
        case .authoringPending:
            statusPhrase = "coming soon"
        case .gatedBehindProgression:
            statusPhrase = "keep exploring to unlock"
        case .gatedBehindConsent:
            statusPhrase = "needs a grown-up to turn on"
        }
        return "\(record.displayTitle). \(statusPhrase)."
    }
}
