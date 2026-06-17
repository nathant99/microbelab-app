import SwiftUI
import Models
import Services

/// Consumer view for the Phase 3 historical context card catalog. Renders
/// one row per `HistoricalContextCardRecord` and surfaces the right
/// affordance per `HistoricalContextService.CardPresentation`:
///
/// - **`.ready`** — reviewer-signed-off prose body. The view currently
///   renders a placeholder body row because no card has shipped reviewer-
///   signoff yet per ADR-016. When the reviewer pathway surfaces signed-off
///   prose, the `.ready` branch swaps to render the real body.
/// - **`.authoringPending`** — gate + consent are clear, but the card body
///   is still `.placeholder` / `.draftAwaitingReview`. Renders the warm
///   "Coming soon" affordance per the trauma-informed register.
/// - **`.gatedBehindProgression`** — `disease-story-immune` gate isn't open
///   yet. Renders the ProgressionService unlock-hint (already stoplist-
///   pinned by ProgressionService tests; copy never reads as failure).
/// - **`.gatedBehindConsent`** — parent has not opted into disease-story
///   arcs (cards share the same consent kind per ADR-016). Renders a
///   parent-handoff affordance pointing at Settings' "For parents" surface.
///
/// **Trauma-informed posture + anti-credentialism gate** (load-bearing per
/// `.claude/rules/trauma-informed-content.md` + CQ CONTENT_STYLE_GUIDE.md
/// § 4.5 anti-credentialism gate): figures are framed as patient observers,
/// NEVER hero-myth lexicon. Koch leads (methodology spine — pattern
/// noticing, not death-counting). Pasteur + Salk follow (vaccine arcs).
/// Marshall closes (kid-scientist register — patient observation paying
/// off, NEVER dangerous-bravado lexicon for the self-inoculation). Every
/// copy string the view renders avoids warfare / shame / threat / fear-
/// induction lexicon.
///
/// **Cross-references** carry through to the view layer as small chips:
///
/// - `record.relevantMicrobeSlugs` — the codex cast members the card
///   anchors on (Marshall ↔ Pylo from PR #119 is the only currently-wired
///   bridge; the others are anchored on TB / cholera / polio which aren't
///   in the kid catalog)
/// - `record.crossPortfolioBridges` — sibling portfolio apps with
///   curricular overlap (Pasteur ↔ labsmith, Marshall ↔ curiosityquest).
///   Future deep-link to spark-anvil-site app pages lands in a focused
///   round; for now the chips surface the bridge name without action.
///
/// **Reachability**: this view is only reachable via the `MicrobiomeView`
/// toolbar when the `historicalContext:` parameter is non-nil. AppRootView
/// wires the canonical service through.
public struct HistoricalContextCardsView: View {
    let historicalContext: HistoricalContextService
    let progression: ProgressionService?
    let consent: ParentalConsentService?

    public init(
        historicalContext: HistoricalContextService,
        progression: ProgressionService? = nil,
        consent: ParentalConsentService? = nil
    ) {
        self.historicalContext = historicalContext
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
                Text("About these cards")
            } footer: {
                Text(verbatim: "Cards ship one at a time after a reviewer signs off on the patient-observation register. You'll see new figures appear here when they're ready.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(historicalContext.catalog) { record in
                    cardRow(for: record)
                }
            } header: {
                Text("Patient observers")
            }
        }
        .navigationTitle("Historical context")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var introCopy: String {
        // Trauma-informed + anti-credentialism intro: names the register
        // (patient observation, careful experiments) + names the kid's
        // agency (skip is always allowed) + names the parent role (opt-in).
        // Stays warm; does NOT promise specific content. Stoplist-pinned by
        // record-tier tests.
        "These cards meet scientists who watched microbes carefully — and changed how we understood them. Skipping is always allowed, and a grown-up turns these cards on with you."
    }

    @ViewBuilder
    private func cardRow(for record: HistoricalContextCardRecord) -> some View {
        let gateOpen = progression?.isUnlocked(record.gateID) ?? false
        let parentConsented = consent?.hasValidConsent(for: .diseaseStoryArcs) ?? false
        let presentation = historicalContext.presentation(
            for: record,
            gateOpen: gateOpen,
            parentConsented: parentConsented
        )
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: record.displayTitle)
                        .font(.headline)
                    Text(verbatim: record.era)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusChip(for: presentation)
            }
            Text(verbatim: record.contribution)
                .font(.caption)
                .foregroundStyle(.secondary)
            presentationBody(for: presentation, record: record)
                .font(.callout)
                .foregroundStyle(.primary)
            if !record.relevantMicrobeSlugs.isEmpty || !record.crossPortfolioBridges.isEmpty {
                bridgeChips(for: record)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: presentation, record: record))
    }

    @ViewBuilder
    private func presentationBody(
        for presentation: HistoricalContextService.CardPresentation,
        record: HistoricalContextCardRecord
    ) -> some View {
        switch presentation {
        case .ready:
            // Reviewer-signoff has landed; structural body renders a
            // placeholder until per-card prose ships per ADR-016. Swap
            // for rendered body content when prose arrives.
            Text(verbatim: "Card ready. Tap to read.")
                .foregroundStyle(.secondary)
        case .authoringPending:
            Text(verbatim: "Coming soon — a reviewer is reading this card now.")
                .foregroundStyle(.secondary)
        case .gatedBehindProgression:
            if let hint = progression?.unlockHint(for: record.gateID) {
                Text(verbatim: hint)
                    .foregroundStyle(.secondary)
            } else {
                Text(verbatim: "Play across a few more days to meet this card.")
                    .foregroundStyle(.secondary)
            }
        case .gatedBehindConsent:
            Text(verbatim: "A grown-up turns these cards on in Settings — under \"For parents.\"")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func bridgeChips(for record: HistoricalContextCardRecord) -> some View {
        // Surface cross-references as small chips. Future rounds wire deep
        // links into the codex (microbe slugs) + spark-anvil-site (portfolio
        // bridges). For now the chips surface the bridge so the kid + parent
        // see the curricular overlap.
        FlowChipRow(items: bridgeItems(for: record))
            .accessibilityHidden(true)
    }

    private func bridgeItems(for record: HistoricalContextCardRecord) -> [BridgeChipItem] {
        var items: [BridgeChipItem] = []
        for slug in record.relevantMicrobeSlugs {
            items.append(BridgeChipItem(label: "Cast: \(slug.capitalized)", systemImage: "circle.hexagongrid.fill"))
        }
        for app in record.crossPortfolioBridges {
            items.append(BridgeChipItem(label: "App: \(app)", systemImage: "rectangle.stack.fill"))
        }
        return items
    }

    private func statusChip(for presentation: HistoricalContextService.CardPresentation) -> some View {
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
        for presentation: HistoricalContextService.CardPresentation,
        record: HistoricalContextCardRecord
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
        return "\(record.displayTitle), \(record.era). \(record.contribution). \(statusPhrase)."
    }
}

/// Local value type for the per-card bridge chip row. Kept inline so the
/// view file is self-contained; the chip pattern is simple enough that
/// extracting to SharedUI would be premature.
private struct BridgeChipItem: Identifiable, Sendable {
    let id = UUID()
    let label: String
    let systemImage: String
}

/// Compact horizontal row of chips that wraps to a second line on narrow
/// screens. Uses HStack with `.wrappingHStack`-style fallback via a simple
/// VStack-of-HStacks layout to keep the row layout-independent of the
/// underlying view system. Kept private to this file.
private struct FlowChipRow: View {
    let items: [BridgeChipItem]

    var body: some View {
        // Simple 2-column row layout. The card row max items observed is 2
        // (Marshall → "Cast: Pylo" + "App: curiosityquest"); the single-row
        // approximation is fine. If a future card surfaces > 2 bridges, the
        // ScrollView-based flow gives gracefully.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items) { item in
                    Label(item.label, systemImage: item.systemImage)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
