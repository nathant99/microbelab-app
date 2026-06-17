import SwiftUI
import Models
import Services
import SharedUI
import ForgeCelebration

/// Codex tab. Renders the 12-microbe grid; locked entries show "???" until
/// the kid discovers them. Discovery flows through the persistent
/// `DiscoveryStore` (Services/Engagement/) so meets carry across cold
/// launches; the codex card tap surface is the primary kid-facing
/// discovery affordance, but `ExploreView`'s rare-microbe sighting + the
/// curious-explorer easter egg also write through to the same store so
/// microscope-side meets keep the codex synchronized.
///
/// Hosts a NavigationStack so the toolbar surfaces a quiz-kits entry
/// point.
public struct MicrobeCodexView: View {
    private let catalog: MicrobeCatalogService
    private let kitService: QuestionKitService
    private let gamification: GamificationService?
    private let celebration: CelebrationCoordinator?
    private let sensory: SensoryPaletteCoordinator?
    private let discovery: DiscoveryStore?
    private let attemptStore: QuestionAttemptStore?
    private let mastery: MicrobeMasteryService?
    private let chapters: MicrobeChapterStore
    @State private var availableKits: [QuestionKit] = []
    @State private var presentedKit: QuestionKit?
    @State private var presentedChapter: PresentedChapter?
    @State private var knowledgeGraph: MicrobeKnowledgeGraph?
    /// Per-session mastery moment detector. The codex axis fires once
    /// when the kid has discovered every microbe in the catalog (12 / 12);
    /// the ecology + defense axes are wired in `MicrobiomeView` /
    /// `ImmuneGameView` respectively. Per-session state via `@State` so
    /// cold launches reset; persistence stays in the discovery store.
    @State private var masteryDetector = MasteryMomentDetector()

    public init(
        catalog: MicrobeCatalogService,
        kitService: QuestionKitService = QuestionKitService(),
        gamification: GamificationService? = nil,
        celebration: CelebrationCoordinator? = nil,
        sensory: SensoryPaletteCoordinator? = nil,
        discovery: DiscoveryStore? = nil,
        attemptStore: QuestionAttemptStore? = nil,
        mastery: MicrobeMasteryService? = nil,
        chapters: MicrobeChapterStore = MicrobeChapterStore()
    ) {
        self.catalog = catalog
        self.kitService = kitService
        self.gamification = gamification
        self.celebration = celebration
        self.sensory = sensory
        self.discovery = discovery
        self.attemptStore = attemptStore
        self.mastery = mastery
        self.chapters = chapters
    }

    /// Sheet item for the chapter reader. Carries the chapter + the
    /// microbe display name so the reader sheet doesn't need a catalog
    /// lookup at present-time.
    private struct PresentedChapter: Identifiable {
        let chapter: MicrobeChapter
        let microbeDisplayName: String
        let microbe: MicrobeCharacter
        var id: String { chapter.slug }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                if let recommendedName = recommendedNextDisplayName() {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.tint)
                        Text("Ready to look closer at: \(recommendedName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Suggested next microbe: \(recommendedName)"))
                }
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(catalog.microbes) { microbe in
                        Button {
                            handleCardTap(microbe: microbe)
                        } label: {
                            MicrobeCodexCard(
                                microbe: microbe,
                                isDiscovered: isDiscovered(microbe),
                                livesNearDisplayNames: livesNearDisplayNames(for: microbe),
                                sameKindDisplayNames: sameKindDisplayNames(for: microbe),
                                hasChapter: chapters.chapter(for: microbe.slug) != nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(Text(verbatim: "Codex"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    quizMenu
                }
            }
            .onAppear {
                if availableKits.isEmpty {
                    availableKits = kitService.loadAllPhase1Kits()
                }
                if knowledgeGraph == nil {
                    // Build once per view lifetime; the catalog is bundled
                    // + immutable so we don't need to rebuild on discovery.
                    knowledgeGraph = MicrobeKnowledgeGraph(microbes: catalog.microbes)
                    DebugLog.lifecycle("MicrobeCodexView built ecology graph: \(knowledgeGraph?.nodeCount ?? 0) nodes, \(knowledgeGraph?.edgeCount ?? 0) edges")
                }
                // Cold-launch evaluation: if the kid completed the codex
                // in a previous session AND this is the first visit this
                // session, we don't auto-fire — the detector's
                // `acknowledged` set is per-session so a fresh launch will
                // surface the moment on the next discovery write rather
                // than retroactively on cold open.
            }
            .sheet(item: $presentedKit) { kit in
                NavigationStack {
                    QuizView(
                        kit: kit,
                        gamification: gamification,
                        celebration: celebration,
                        sensory: sensory,
                        attemptStore: attemptStore
                    )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { presentedKit = nil }
                            }
                        }
                }
            }
            .sheet(item: $presentedChapter) { item in
                ChapterReaderSheet(
                    chapter: item.chapter,
                    microbeDisplayName: item.microbeDisplayName,
                    microbe: item.microbe,
                    isMicrobeDiscovered: true,
                    bundle: MicrobeChapterStore.resourcesBundle
                )
            }
        }
    }

    private var quizMenu: some View {
        Menu {
            if availableKits.isEmpty {
                Text("No kits available")
            } else {
                ForEach(availableKits) { kit in
                    Button {
                        presentedKit = kit
                    } label: {
                        Label("Kit \(kit.kitNumber): \(kit.title)", systemImage: "questionmark.circle")
                    }
                }
            }
        } label: {
            Label("Quizzes", systemImage: "questionmark.circle")
        }
        .accessibilityHint("Browse question kits")
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: 12)]
    }

    /// Card tap handler. For undiscovered microbes this is the kid's
    /// primary discovery affordance — the tap writes through the
    /// `DiscoveryStore` + fires the per-discovery sensory cue + runs the
    /// codex mastery check. For already-discovered cards the tap surfaces
    /// the microbe's DN-S chapter when one is bundled (the 6 canonical
    /// cast: Lacto / Yeast / Photo / Net / Spore / Guard); cards for the
    /// codex-supporting cast members without authored chapters keep the
    /// existing no-op behavior.
    private func handleCardTap(microbe: MicrobeCharacter) {
        if isDiscovered(microbe) {
            // Re-meeting a microbe through the codex counts as a reinforcement
            // encounter for the mastery model — the FSRS-6 rolling-window
            // accuracy updates, the recommendation picker re-ranks. The
            // recordEncounter call no-ops when `mastery` is nil OR the slug
            // isn't in the graph.
            mastery?.recordEncounter(slug: microbe.slug, wasCorrect: true)
            if let chapter = chapters.chapter(for: microbe.slug) {
                presentedChapter = PresentedChapter(
                    chapter: chapter,
                    microbeDisplayName: microbe.displayName,
                    microbe: microbe
                )
                DebugLog.state("MicrobeCodexView opened chapter reader: \(microbe.slug)")
            }
            return
        }
        guard let discovery else { return }
        discovery.markDiscovered(slug: microbe.slug)
        // First encounter on this microbe — record against the mastery
        // surface so the FSRS-6 retention curve begins tracking.
        mastery?.recordEncounter(slug: microbe.slug, wasCorrect: true)
        // Per-discovery sensory cue — distinct from the mastery moment
        // celebration; this gives the kid a small confirmation that the
        // tap landed without overloading the every-tap surface.
        sensory?.fire(.achievement)
        DebugLog.state("MicrobeCodexView marked discovered: \(microbe.slug); total now \(discovery.discoveredSlugs.count)/\(catalog.microbes.count)")
        evaluateCodexMastery()
    }

    /// Returns the display name of the recommended-next-to-deepen microbe
    /// from `MicrobeMasteryService.recommendedNextMicrobe(among:)`. Returns
    /// `nil` when no recommendation exists (mastery service absent / no
    /// discoveries yet / no frontier candidates / kid has discovered ≤ 1
    /// microbe — the caption only surfaces after the kid has built a small
    /// discovery set so the recommendation feels earned). Trauma-informed
    /// posture: caption never frames recommendation as deficiency.
    private func recommendedNextDisplayName() -> String? {
        guard let mastery, let discovery else { return nil }
        // Hide the caption until the kid has at least 2 discoveries — the
        // single-microbe case can only ever surface the microbe they JUST
        // discovered, which reads as redundant nudging.
        guard discovery.discoveredSlugs.count >= 2 else { return nil }
        guard let slug = mastery.recommendedNextMicrobe(among: discovery.discoveredSlugs) else { return nil }
        return catalog.microbes.first { $0.slug == slug }?.displayName
    }

    /// Run the codex mastery check. Fires `.codexMaster` exactly once per
    /// session when the kid has discovered every microbe in the catalog;
    /// follow-up taps are no-ops via the detector's `acknowledged` set.
    /// Mirrors the ecology + defense axes in `MicrobiomeView` /
    /// `ImmuneGameView`.
    private func evaluateCodexMastery() {
        guard let discovery else { return }
        guard let moment = masteryDetector.recordCodexDiscovery(
            totalDiscovered: discovery.discoveredSlugs.count,
            totalAvailable: catalog.microbes.count
        ) else { return }
        DebugLog.state("MicrobeCodexView codex mastery moment: \(moment.headline)")
        celebration?.personalBest(metric: moment.headline, value: "\(catalog.microbes.count) / \(catalog.microbes.count) microbes")
        sensory?.fire(.streakMilestone(catalog.microbes.count))
    }

    /// Returns the names of ecology neighbors to surface on a discovered
    /// card. Filters the graph's neighbors to the kid's discovered set so
    /// "Lives near" only references microbes they've actually met.
    /// Returns an empty array for undiscovered cards (the card hides the
    /// line itself based on `isDiscovered`).
    private func livesNearDisplayNames(for microbe: MicrobeCharacter) -> [String] {
        guard isDiscovered(microbe), let graph = knowledgeGraph else { return [] }
        let related = graph.related(to: microbe, limit: 4)
        let discoveredNeighbors = related.filter { isDiscovered($0) }
        // Cap to 2 display names so the card stays scannable.
        return Array(discoveredNeighbors.prefix(2).map(\.displayName))
    }

    /// Returns the names of same-kingdom cohort members surfaced via
    /// `MicrobeKnowledgeGraph.relatedByKingdom(...)`. Filters to the kid's
    /// discovered set + excludes any name already surfaced on the "Lives
    /// near" line so the two captions don't repeat each other (a microbe
    /// in the same habitat AND same kingdom only appears once, on the
    /// "Lives near" line — that's the stronger relation for the kid's
    /// mental model). Cap to 2 display names so the card stays scannable.
    /// Returns an empty array for undiscovered cards (the card hides the
    /// line itself based on `isDiscovered`).
    private func sameKindDisplayNames(for microbe: MicrobeCharacter) -> [String] {
        guard isDiscovered(microbe), let graph = knowledgeGraph else { return [] }
        let already = Set(livesNearDisplayNames(for: microbe))
        let cohort = graph.relatedByKingdom(to: microbe, limit: 4)
        let discoveredCohort = cohort.filter {
            isDiscovered($0) && !already.contains($0.displayName)
        }
        return Array(discoveredCohort.prefix(2).map(\.displayName))
    }

    /// True iff the discovery store contains the microbe's slug. When no
    /// store is wired (test fixtures / preview rendering) every card
    /// reads as undiscovered so the "???" surface is the default.
    private func isDiscovered(_ microbe: MicrobeCharacter) -> Bool {
        guard let discovery else { return false }
        return discovery.discoveredSlugs.contains(microbe.slug)
    }
}
