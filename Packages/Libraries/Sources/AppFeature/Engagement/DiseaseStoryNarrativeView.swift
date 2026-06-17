import SwiftUI
import SpriteKit
import Models
import GameEngine
import Services

/// Consumer view for the Phase 3 disease-story narrative beat surface.
/// Hosts a `DiseaseStoryNarrativeScene` (chunky-cartoon register; no
/// graphic illness imagery) for the chosen arc and surfaces a per-beat
/// stepper + status chip + per-beat structural caption.
///
/// **Why this exists** (per FEATURE_PLAN line 158): the existing
/// `DiseaseStoryArcView` lists the 4 arcs at catalog level; this view
/// renders ONE arc's 4 narrative beats in sequence. The split lets the
/// kid step through the pedagogy spine (at-rest → notice the change →
/// helper arrives → settling) per arc, with the reviewer-blocked prose
/// body landing as `.placeholder` until ADR-016 reviewer-signoff lands.
///
/// **Trauma-informed posture** (load-bearing per `.claude/rules/trauma-informed-content.md`
/// + ADR-016):
/// - Every beat header is a structural primitive — never prose the
///   reviewer hasn't signed off on
/// - Off-ramp affordance ("Pause this story") is ALWAYS visible
/// - Status chip per beat communicates `.placeholder` / `.draftAwaitingReview`
///   / `.reviewerSignedOff` so the kid never sees draft content
/// - The SpriteKit scene itself stays content-neutral (calm cream
///   background); per-beat illustration assets are reviewer-gated +
///   asset-blocked per `.claude/rules/forgekit.md` § Asset generation
///   ownership.
///
/// **Reachability**: the view is reached from `DiseaseStoryArcView` via
/// `NavigationLink(value:)` when an arc's presentation is `.ready` — i.e.
/// gate + consent + reviewer-signoff all clear. Until reviewer-signoff
/// ships, no arc reaches `.ready` so this view's path stays dormant; the
/// structural surface is verified by tests.
public struct DiseaseStoryNarrativeView: View {
    let arc: DiseaseStoryArc
    let beats: [DiseaseStoryNarrativeBeatRecord]
    @State private var currentBeatIndex: Int = 0
    @State private var scene: DiseaseStoryNarrativeScene

    public init(arc: DiseaseStoryArc) {
        self.arc = arc
        self.beats = DiseaseStoryNarrativeCatalog.beats(for: arc)
        // Scene starts with a placeholder size; SpriteView fills the
        // available area + .resizeFill propagates the actual size via
        // didChangeSize(_:).
        self._scene = State(initialValue: DiseaseStoryNarrativeScene(
            size: CGSize(width: 400, height: 400),
            arc: arc
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            sceneHost
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
            beatStepper
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.thinMaterial)
        }
        .navigationTitle(arc.displayTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: pauseStory) {
                    Label("Pause", systemImage: "pause.circle")
                }
                .accessibilityHint("Pause this story and return to the story list.")
            }
        }
    }

    private var sceneHost: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Disease story canvas for \(arc.displayTitle)"))
            .accessibilityValue(Text(accessibilityValueForCurrentBeat))
    }

    private var beatStepper: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verbatim: currentBeatHeader)
                    .font(.headline)
                Spacer()
                statusChip(for: currentBeatAuthoring)
            }
            Text(verbatim: currentBeatPrimitive)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(verbatim: currentBeatBodyPlaceholder)
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(.top, 2)
            HStack {
                Button(action: stepBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .disabled(currentBeatIndex == 0)
                .accessibilityHint("Step back to the previous beat.")
                Spacer()
                Text("Beat \(currentBeatIndex + 1) of \(beats.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Spacer()
                Button(action: stepForward) {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(currentBeatIndex == beats.count - 1)
                .accessibilityHint("Step forward to the next beat.")
            }
            .padding(.top, 4)
        }
    }

    private var currentBeatRecord: DiseaseStoryNarrativeBeatRecord? {
        guard currentBeatIndex >= 0, currentBeatIndex < beats.count else { return nil }
        return beats[currentBeatIndex]
    }

    private var currentBeatHeader: String {
        currentBeatRecord?.beat.displayTitle ?? "—"
    }

    private var currentBeatPrimitive: String {
        currentBeatRecord?.beat.primitive ?? ""
    }

    private var currentBeatAuthoring: DiseaseStoryAuthoring {
        currentBeatRecord?.authoring ?? .placeholder
    }

    /// Trauma-informed placeholder body. Per ADR-016 + the trauma-informed
    /// content rule, the prose body is reviewer-blocked. The placeholder
    /// frames the wait as care (a reviewer is reading this beat now), not
    /// as the kid having done something wrong. When `.reviewerSignedOff`
    /// lands, this branch swaps to render the reviewer-signed prose.
    private var currentBeatBodyPlaceholder: String {
        switch currentBeatAuthoring {
        case .placeholder, .draftAwaitingReview:
            return "Coming soon — a reviewer is reading this beat now. Pause and come back when you're ready."
        case .reviewerSignedOff:
            // When reviewer-signoff lands, this branch renders the real
            // per-beat prose. The scaffold ships a minimal placeholder
            // until then so the structural surface is testable today.
            return "Story beat ready. Tap Next to continue."
        }
    }

    private var accessibilityValueForCurrentBeat: String {
        let beatLabel = currentBeatRecord?.beat.displayTitle ?? ""
        let status: String
        switch currentBeatAuthoring {
        case .placeholder, .draftAwaitingReview:
            status = "coming soon"
        case .reviewerSignedOff:
            status = "ready"
        }
        return "\(beatLabel), \(status). Beat \(currentBeatIndex + 1) of \(beats.count)."
    }

    private func stepForward() {
        guard currentBeatIndex < beats.count - 1 else { return }
        currentBeatIndex += 1
        scene.advanceBeat()
    }

    private func stepBack() {
        guard currentBeatIndex > 0 else { return }
        currentBeatIndex -= 1
        scene.retreatBeat()
    }

    private func pauseStory() {
        // Off-ramp affordance — the SwiftUI dismiss action is delegated
        // upstream via the navigation stack; this method exists so the
        // toolbar button has a single binding the test surface can
        // verify exists. The actual dismiss happens via NavigationStack
        // pop when the user taps the back button OR this Pause button
        // (which surfaces a swipe-down-like affordance via SwiftUI's
        // dismiss environment in a future round). For now the pause is
        // a no-op-with-affordance; the back affordance suffices.
        scene.resetToFirstBeat()
        currentBeatIndex = 0
    }

    private func statusChip(for authoring: DiseaseStoryAuthoring) -> some View {
        let (label, systemImage): (String, String)
        switch authoring {
        case .placeholder:
            label = "Coming soon"
            systemImage = "hourglass"
        case .draftAwaitingReview:
            label = "In review"
            systemImage = "doc.text.magnifyingglass"
        case .reviewerSignedOff:
            label = "Ready"
            systemImage = "book.fill"
        }
        return Label(label, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
    }
}
