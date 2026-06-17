import SwiftUI
import Models
import Services

/// Consumer view for the Phase 3 vaccine mini-explainer catalog. Renders one
/// row per `VaccineExplainerStepRecord` and surfaces the right affordance per
/// `VaccineExplainerService.StepPresentation`:
///
/// - **`.ready`** — reviewer-signed-off prose body. The view currently renders
///   a placeholder body row because no step has shipped reviewer-signoff yet
///   per ADR-016. When the reviewer pathway surfaces signed-off prose, the
///   `.ready` branch swaps to render the real body. The structural surface
///   lands now so the kid path is complete the moment prose arrives.
/// - **`.authoringPending`** — gate + consent are clear, but the step body is
///   still `.placeholder` / `.draftAwaitingReview`. Renders the warm
///   "Coming soon" affordance per the trauma-informed register.
/// - **`.gatedBehindProgression`** — `disease-story-immune` gate isn't open
///   yet. Renders the ProgressionService unlock-hint (already stoplist-pinned
///   by ProgressionService tests; copy never reads as failure).
/// - **`.gatedBehindConsent`** — parent has not opted into disease-story arcs
///   (the explainer shares the same consent kind per ADR-016). Renders a
///   parent-handoff affordance pointing at Settings' "For parents" surface.
///
/// **Trauma-informed posture** (load-bearing per
/// `.claude/rules/trauma-informed-content.md` + Docs/TECHNICAL_DESIGN.md §
/// Trauma-Informed Design Posture): vaccines are framed as the body's
/// library learning a shape ahead of meeting it live — never as warfare,
/// never as fear hook. Every copy string the view renders avoids warfare /
/// shame / threat / fear-induction lexicon. The view's tests pin a
/// parameterized stoplist at unit-test time so a future copy edit can't
/// regress the property.
///
/// **Pairs with** the Phase 2 adaptive-immunity arc (B-cell antibody
/// matching, `BCellAntibodyMatchScene`) so the kid sees the connection
/// without re-teaching the primitive. The same `disease-story-immune` gate
/// (5 sessions + 3 immune runs) opens both surfaces at the same boundary.
///
/// **Reachability**: this view is only reachable via the `MicrobiomeView`
/// toolbar when the `vaccineExplainer:` parameter is non-nil. AppRootView
/// wires the canonical service through. Per-step deep-link flows land in a
/// future round when the `.ready` body content lands per ADR-016 reviewer
/// signoff.
public struct VaccineExplainerView: View {
    let vaccineExplainer: VaccineExplainerService
    let progression: ProgressionService?
    let consent: ParentalConsentService?

    public init(
        vaccineExplainer: VaccineExplainerService,
        progression: ProgressionService? = nil,
        consent: ParentalConsentService? = nil
    ) {
        self.vaccineExplainer = vaccineExplainer
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
                Text("About this explainer")
            } footer: {
                Text(verbatim: "Each step ships one at a time after a reviewer signs off on the trauma-informed register. You'll see new beats appear here when they're ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(vaccineExplainer.catalog) { record in
                    stepRow(for: record)
                }
            } header: {
                Text("Pedagogy beats")
            }
        }
        .navigationTitle("Vaccine explainer")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var introCopy: String {
        // Trauma-informed intro: names the why (curiosity + library register,
        // continuous with adaptive-immunity) + names the kid's agency (skip
        // is always allowed) + names the parent role (opt-in). Stays warm;
        // does NOT promise specific content. Stoplist-pinned by tests.
        "Vaccines help the body's library practice a shape before meeting it live. These short beats build on what you already met in the immune library. Skipping is always allowed, and a grown-up turns this on with you."
    }

    @ViewBuilder
    private func stepRow(for record: VaccineExplainerStepRecord) -> some View {
        let gateOpen = progression?.isUnlocked(VaccineExplainerService.explainerGateID) ?? false
        let parentConsented = consent?.hasValidConsent(for: .diseaseStoryArcs) ?? false
        let presentation = vaccineExplainer.presentation(
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
            presentationBody(for: presentation)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: presentation, record: record))
    }

    @ViewBuilder
    private func presentationBody(for presentation: VaccineExplainerService.StepPresentation) -> some View {
        switch presentation {
        case .ready:
            // Reviewer-signoff has landed; the structural body renders a
            // placeholder line until per-step prose ships in a focused round
            // (per ADR-016). When prose arrives, swap this for the rendered
            // body content.
            Text(verbatim: "Step ready. Tap the beat to read.")
                .foregroundStyle(.secondary)
        case .authoringPending:
            Text(verbatim: "Coming soon — a reviewer is reading this beat now.")
                .foregroundStyle(.secondary)
        case .gatedBehindProgression(let record):
            // Trauma-informed: the unlock-hint copy never reads as failure
            // — ProgressionService.unlockHint already runs through a stoplist
            // test. We surface the canonical unlock hint when available; the
            // canonical fallback is a per-step warm "keep exploring" line.
            if let hint = progression?.unlockHint(for: VaccineExplainerService.explainerGateID) {
                Text(verbatim: hint)
                    .foregroundStyle(.secondary)
            } else {
                Text(verbatim: warmKeepExploringCopy(for: record))
                    .foregroundStyle(.secondary)
            }
        case .gatedBehindConsent:
            Text(verbatim: "A grown-up turns this explainer on in Settings — under \"For parents.\"")
                .foregroundStyle(.secondary)
        }
    }

    /// Trauma-informed fallback line when ProgressionService isn't threaded
    /// in (preview / unit-test contexts). Per-step so the warmth feels
    /// specific rather than generic. Stoplist-pinned by view tests.
    private func warmKeepExploringCopy(for record: VaccineExplainerStepRecord) -> String {
        switch record.step {
        case .introduction:
            return "Play across a few more days to meet this gentle introduction."
        case .antibodyPriming:
            return "Keep practicing in the immune library — this beat opens after a few defense runs."
        case .memoryFormation:
            return "The memory beat opens once the body has met a few shapes."
        case .boosterRationale:
            return "Boosters unlock after the kid has spent time in the immune library."
        }
    }

    private func statusChip(for presentation: VaccineExplainerService.StepPresentation) -> some View {
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
        for presentation: VaccineExplainerService.StepPresentation,
        record: VaccineExplainerStepRecord
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
