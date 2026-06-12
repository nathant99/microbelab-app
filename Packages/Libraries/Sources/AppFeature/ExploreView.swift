import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor

/// Microscope tab. Wraps `MicroscopeScene` via `SpriteView`, floats the tier-
/// badge HUD over the scene per `.claude/rules/spritekit.md` § SpriteView
/// layout cascade (`safeAreaInset` for the floating overlay).
public struct ExploreView: View {
    @State private var scene: MicroscopeScene
    @State private var currentTier: ZoomTier = .unaided
    @State private var mentorMessage: String
    @State private var easterEgg = EasterEggDetector()
    // Captures a rare-sighting microbe slug surfaced at init so .onAppear
    // can write it to the recall store (init() can't touch the @Observable).
    @State private var sightingToRecord: String?

    private let catalog: MicrobeCatalogService
    private let mentor: VeeMentor
    private let sessionCount: Int
    private let analytics: AnalyticsService?
    private let recall: MentorRecallStore?

    public init(
        catalog: MicrobeCatalogService,
        mentor: VeeMentor,
        sessionCount: Int = 0,
        analytics: AnalyticsService? = nil,
        recall: MentorRecallStore? = nil
    ) {
        self.catalog = catalog
        self.mentor = mentor
        self.sessionCount = sessionCount
        self.analytics = analytics
        self.recall = recall
        // The scene's size is reset by `.resizeFill` once SpriteView lays out.
        let initialScene = MicroscopeScene(size: CGSize(width: 400, height: 600))
        _scene = State(initialValue: initialScene)

        // Mentor callback layer takes priority over the variable-reward and
        // default cold-open copy when the kid has previously met a microbe
        // here. Per Docs/FEATURE_PLAN.md § Delight & Polish → "Character
        // personality" item: warm "you've been here before" framing only.
        let slugs = catalog.microbes.map(\.slug).sorted()
        if let recallEntry = recall?.entry(for: sessionCount),
           let line = Self.callbackCopy(for: recallEntry, mentor: mentor) {
            _mentorMessage = State(initialValue: line)
        } else if let reward = VariableRewardSelector.select(
            forSessionCount: sessionCount,
            microbeSlugs: slugs
        ) {
            // Stash the slug so onAppear records the meet in the recall
            // store; the @Observable mutation can't run from init().
            if case let .rareMicrobeSighting(slug) = reward {
                _sightingToRecord = State(initialValue: slug)
            }
            _mentorMessage = State(initialValue: Self.copy(for: reward, catalog: catalog))
        } else {
            _mentorMessage = State(initialValue: "Pinch in to zoom. There are tiny lives waiting to be seen.")
        }
    }

    /// Compose the cold-open callback line referencing a microbe the kid has
    /// met before. Pure (no view state); the rotation index is the kid's
    /// session count so each session can pick a different recent meet.
    /// MainActor-isolated by default since `VeeMentor` is @MainActor.
    static func callbackCopy(
        for entry: MentorRecallEntry,
        mentor: VeeMentor
    ) -> String? {
        let days = max(0, Calendar.current.dateComponents(
            [.day], from: entry.lastSeenAt, to: Date()
        ).day ?? 0)
        return mentor.recallCue(for: entry.slug, daysSinceLastSeen: days)
    }

    /// Translate a `VariableReward` into the mentor-bubble copy line. Lives
    /// here (not in Services) so the copy can quote the canonical display
    /// name from the catalog instead of a slug.
    nonisolated static func copy(
        for reward: VariableReward,
        catalog: MicrobeCatalogService
    ) -> String {
        switch reward {
        case .rareMicrobeSighting(let slug):
            let displayName = catalog.microbes
                .first(where: { $0.slug == slug })?
                .displayName ?? "Someone"
            return "\(displayName) is hanging around today. See if you can spot them."
        case .specialMentorMoment:
            return "Quiet day under the lens. Take your time — I'm right here."
        }
    }

    public var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .ignoresSafeArea()
            .safeAreaInset(edge: .top, spacing: 8) {
                MicroscopeHUD(currentTier: currentTier) { tier in
                    scene.snapToTier(tier)
                    let resolved = scene.machine.currentTier
                    currentTier = resolved
                    // Record the visit BEFORE deciding what cue to show — the
                    // detector is the only surface that knows whether THIS
                    // tap was the all-tiers-reached beat.
                    let unlocked = easterEgg.record(visit: resolved)
                    if unlocked {
                        surfaceCuriousExplorerCue()
                        easterEgg.acknowledgeAllTiersReached()
                        DebugLog.state("ExploreView easter egg unlocked at tier=\(resolved)")
                    } else {
                        refreshMentorCue(for: resolved)
                    }
                    DebugLog.state("ExploreView snap to \(tier); visitedTiers=\(easterEgg.visitedTiers.count)")
                    if let analytics {
                        Task { await analytics.track(.zoomTierReached(tier: resolved)) }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .safeAreaInset(edge: .bottom, spacing: 8) {
                MentorBubble(message: mentorMessage)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
            .onAppear {
                DebugLog.lifecycle("ExploreView onAppear; catalog=\(catalog.microbes.count) microbes")
                if let slug = sightingToRecord {
                    recall?.record(slug: slug)
                    sightingToRecord = nil
                    DebugLog.state("ExploreView recorded recall sighting: \(slug)")
                }
            }
    }

    /// Pull a static mentor cue for the new tier. Async generated cues land
    /// once the AI surface is wired to the speech-bubble (separate PR).
    private func refreshMentorCue(for tier: ZoomTier) {
        let cue = mentor.fallbackZoomCue(for: tier)
        mentorMessage = "\(cue.reaction) \(cue.lookForHint)"
    }

    /// Surface the curious-explorer easter-egg cue. Quotes a canonical
    /// microbe display name + frames the moment as warm recognition (not
    /// loss-aversion). The microbe pick is deterministic per session so
    /// the slug never flickers between re-renders.
    private func surfaceCuriousExplorerCue() {
        let slugs = catalog.microbes.map(\.slug).sorted()
        let pickedSlug = EasterEggDetector.curiousExplorerMicrobe(
            forSessionCount: sessionCount,
            microbeSlugs: slugs
        )
        let displayName = pickedSlug
            .flatMap { slug in catalog.microbes.first(where: { $0.slug == slug })?.displayName }
            ?? "a curious neighbor"
        mentorMessage = "You walked the whole range today. \(displayName) usually only shows up for the careful ones — thanks for looking."
    }
}
