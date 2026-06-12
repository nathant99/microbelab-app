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

    private let catalog: MicrobeCatalogService
    private let mentor: VeeMentor
    private let sessionCount: Int

    public init(
        catalog: MicrobeCatalogService,
        mentor: VeeMentor,
        sessionCount: Int = 0
    ) {
        self.catalog = catalog
        self.mentor = mentor
        self.sessionCount = sessionCount
        // The scene's size is reset by `.resizeFill` once SpriteView lays out.
        let initialScene = MicroscopeScene(size: CGSize(width: 400, height: 600))
        _scene = State(initialValue: initialScene)

        // Variable-reward cue replaces the default cold-open mentor copy on
        // ~1 in 5 sessions per the engagement-foundation cadence.
        let slugs = catalog.microbes.map(\.slug).sorted()
        if let reward = VariableRewardSelector.select(
            forSessionCount: sessionCount,
            microbeSlugs: slugs
        ) {
            _mentorMessage = State(initialValue: Self.copy(for: reward, catalog: catalog))
        } else {
            _mentorMessage = State(initialValue: "Pinch in to zoom. There are tiny lives waiting to be seen.")
        }
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
                    currentTier = scene.machine.currentTier
                    refreshMentorCue(for: scene.machine.currentTier)
                    DebugLog.state("ExploreView snap to \(tier)")
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
            }
    }

    /// Pull a static mentor cue for the new tier. Async generated cues land
    /// once the AI surface is wired to the speech-bubble (separate PR).
    private func refreshMentorCue(for tier: ZoomTier) {
        let cue = mentor.fallbackZoomCue(for: tier)
        mentorMessage = "\(cue.reaction) \(cue.lookForHint)"
    }
}
