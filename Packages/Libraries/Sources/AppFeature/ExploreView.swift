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

    public init(catalog: MicrobeCatalogService, mentor: VeeMentor) {
        self.catalog = catalog
        self.mentor = mentor
        // The scene's size is reset by `.resizeFill` once SpriteView lays out.
        let initialScene = MicroscopeScene(size: CGSize(width: 400, height: 600))
        _scene = State(initialValue: initialScene)
        _mentorMessage = State(initialValue: "Pinch in to zoom. There are tiny lives waiting to be seen.")
    }

    public var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .ignoresSafeArea()
            .safeAreaInset(edge: .top, spacing: 8) {
                tierBadgeRow
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

    private var tierBadgeRow: some View {
        HStack(spacing: 6) {
            ForEach(ZoomTier.allCases, id: \.self) { tier in
                TierBadge(tier: tier, isActive: tier == currentTier) {
                    scene.snapToTier(tier)
                    currentTier = scene.machine.currentTier
                    DebugLog.state("ExploreView snap to \(tier)")
                }
            }
        }
    }
}
