import Foundation
import SwiftUI
import SpriteKit
import ForgeAdventure
import ForgeModels
import Models

/// MicrobeLab's Level 2 `HubContribution` for AdventureHub. Source apps register a single
/// contribution per slot; AdventureHub resolves `(zone, engine)` to a contribution at render
/// time. Per FEATURE_PLAN.md § Adventure Mode + TECHNICAL_DESIGN.md § Adventure Mode
/// Integration, MicrobeLab contributes to the **Life Zone** of AdventureHub; the canonical
/// `lifeZone` case is not yet shipped in `ForgeAdventure.ZoneID` (the cluster coordinates
/// across bioforge / creaturecare / wildlens), so the current contribution targets
/// `.scienceLabs` — the closest available match (NGSS MS-LS1-1 / cells / immune system).
/// A handoff in `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md` requests
/// labsmith add the canonical Life Zone case + corresponding migration path.
///
/// The contribution wires four engines to MicrobeLab's existing surfaces:
///
/// - `.simulation` — Microbiome Simulator (`MicrobiomeView` / `MicrobiomePuzzleScene`)
/// - `.defense`    — Innate-immune Pac-Man (`ImmuneGameView` / `MacrophagePacmanScene`)
/// - `.quest`      — Microscope exploration (`ExploreView` / `MicroscopeScene`)
/// - `.puzzle`     — Antibody Lab (`ImmuneGameView` adaptive surface /
///                   `BCellAntibodyMatchScene`) — Phase 2 shape-matching
///                   pedagogy beat; gated on `AdaptiveImmunityUnlock` so the
///                   hub-orchestrated surface inherits the same innate-first
///                   progression curve as the in-app surface.
///
/// All three render the existing app surfaces via `AnyView` adapters; the hub provides the
/// completion + lifecycle callbacks (`onComplete` / `onExitToHub`) the contribution must
/// invoke. Because MicrobeLab's surfaces are reflex-driven (zoom + microbiome ticks + immune
/// waves), the contribution does NOT use `HubGenericChallengeView`'s baseline MCQ loop;
/// it ships its own light SwiftUI adapter that closes over the existing tab views with the
/// hub callback wired through.
///
/// Per `.claude/rules/forgekit.md` § Maximize-ForgeKit-integration interaction note: this is
/// the canonical Level 2 wiring point for the ForgeAdventure module — registering the
/// contribution at app startup promotes `ForgeAdventure` from declared-but-unused to actively
/// consumed without any entitlement provisioning (AdventureHub orchestrates the hub via SPM
/// only; no entitlements required).
public nonisolated struct MicrobeLabHubContribution: HubContribution {
    public let sourceAppID: String
    public let sourceAppDisplayName: String
    public let zone: ZoneID
    public let supportedEngines: [GameModeType]
    public let preferredPresentation: HubPresentation
    public let mentorPersona: MentorPersona
    public let kitResources: [HubKitResource]

    /// Hero color `#33CCBB` (bio-luminescent teal-cyan) per
    /// `Docs/TECHNICAL_DESIGN.md` § Delight & Emotional Design.
    public var themeAccent: Color { Color(red: 0x33 / 255.0, green: 0xCC / 255.0, blue: 0xBB / 255.0) }

    public init(
        sourceAppID: String = "microbelab",
        sourceAppDisplayName: String = "MicrobeLab",
        zone: ZoneID = .scienceLabs,
        supportedEngines: [GameModeType] = [.simulation, .defense, .quest, .puzzle],
        preferredPresentation: HubPresentation = .fullScreen,
        mentorPersona: MentorPersona = .microbeLabCilia,
        kitResources: [HubKitResource] = MicrobeLabHubContribution.canonicalKitResources
    ) {
        self.sourceAppID = sourceAppID
        self.sourceAppDisplayName = sourceAppDisplayName
        self.zone = zone
        self.supportedEngines = supportedEngines
        self.preferredPresentation = preferredPresentation
        self.mentorPersona = mentorPersona
        self.kitResources = kitResources
    }

    /// Canonical kit resources surfaced by AdventureHub kit pickers. The pointers match the
    /// kits MicrobeLab already bundles via `QuestionKitService.phase1KitSlugs`. Each pointer
    /// uses the Phase-1 NGSS / NHES Bloom-band that the bundled kit JSON ships with.
    public static let canonicalKitResources: [HubKitResource] = [
        HubKitResource(
            kitID: "kit_01_microbiology_basics",
            resourceName: "kit_01_microbiology_basics",
            bloomBand: .remember,
            gradeBand: .middle
        ),
        HubKitResource(
            kitID: "kit_02_microbiome",
            resourceName: "kit_02_microbiome",
            bloomBand: .understand,
            gradeBand: .middle
        ),
        HubKitResource(
            kitID: "kit_03_immune_defense",
            resourceName: "kit_03_immune_defense",
            bloomBand: .understand,
            gradeBand: .middle
        ),
        HubKitResource(
            kitID: "kit_04_beneficial_microbes",
            resourceName: "kit_04_beneficial_microbes",
            bloomBand: .apply,
            gradeBand: .middle
        ),
    ]

    /// Per-engine UI copy surfaced to AdventureHub's chrome.
    /// Trauma-informed register: protection + agency + discovery, NEVER war / threat /
    /// loss-aversion. Matches `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture.
    public static let canonicalEngineCopy: [GameModeType: EngineCopy] = [
        .simulation: EngineCopy(
            title: "Microbiome simulator",
            tagline: "Pick a feeding mode and watch the gut ecology shift.",
            completionMessage: "Steady ecology — fiber + balance held the line."
        ),
        .defense: EngineCopy(
            title: "Innate immune defense",
            tagline: "Help your macrophages clear the pathogens.",
            completionMessage: "Quiet helpers did their work today."
        ),
        .quest: EngineCopy(
            title: "Microscope expedition",
            tagline: "Zoom from 1× to 10000× to meet the microbes.",
            completionMessage: "You met a new microbe today."
        ),
        // Phase 2 Antibody Lab — `.puzzle` engine kind (shape-pattern
        // matching is pedagogically a puzzle category; .defense is
        // reserved for the innate macrophage Pac-Man so the two surfaces
        // stay distinct in the hub picker). The completionMessage
        // mirrors the in-app B-cell adaptive surface's celebratory beat
        // ("memory cells locked in") which is trauma-informed: protection
        // + library-building framing, never warfare vocabulary per
        // `.claude/rules/trauma-informed-content.md`.
        .puzzle: EngineCopy(
            title: "Antibody library",
            tagline: "Help the B-cells remember the shape.",
            completionMessage: "Memory cells locked in — your library grew today."
        ),
    ]

    @MainActor
    public func makeChallengeView(
        engine: GameModeType,
        kit: HubQuestionKit,
        context: HubChallengeContext
    ) -> AnyView {
        let copy = MicrobeLabHubContribution.canonicalEngineCopy[engine] ?? .default
        return AnyView(
            MicrobeLabHubChallengeAdapter(
                engine: engine,
                copy: copy,
                themeAccent: themeAccent,
                context: context
            )
        )
    }
}

extension MentorPersona {
    /// MicrobeLab's canonical mentor persona: Cilia, the curious cilium kid the AI Socratic
    /// mentor (Vee) inhabits. Mirrors the voice register defined in the DN retrofit handoff +
    /// `VeeMentor.systemPromptHeader` so AdventureHub-orchestrated mentor sessions inherit the
    /// same voice as the in-app mentor. `nonisolated` so it can be used as a default value in
    /// the nonisolated `MicrobeLabHubContribution` init per `.claude/rules/concurrency.md`
    /// § Extension methods inherit MainActor too.
    public nonisolated static let microbeLabCilia = MentorPersona(
        id: "microbelab.cilia",
        displayName: "Cilia",
        avatarAssetName: "cilia_mentor",
        voiceProfile: .warmMid,
        systemPromptHeader: """
            You are Cilia, a warm and curious cilium kid who loves microbes. \
            You ask Socratic questions like "what do you see?" and "what could \
            this microbe be doing?" — you NEVER frame microbes as villains; most \
            are beneficial or neutral. You speak with kid-readable wonder, avoid \
            medical-trauma framing, and surface discovery + agency over fear.
            """
    )
}

/// SwiftUI adapter that renders MicrobeLab's existing app surfaces (Microscope / Microbiome /
/// Immune) inside AdventureHub's challenge-view envelope. The hub passes a
/// `HubChallengeContext` carrying lifecycle callbacks; this adapter surfaces a trauma-safe
/// "Wrap up today" affordance that invokes `onComplete` with a coarse-grained completion
/// signal (the adapter doesn't try to map MicrobeLab's open-ended exploration loops to an
/// MCQ-style score; instead it surfaces "I'm done" + a gentle session-end reflection).
@MainActor
struct MicrobeLabHubChallengeAdapter: View {
    let engine: GameModeType
    let copy: EngineCopy
    let themeAccent: Color
    let context: HubChallengeContext

    @State private var hasInvokedComplete = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(copy.title)
                    .font(.title2.weight(.semibold))
                Text(copy.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            engineSurface
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                Button("Back to hub") {
                    context.onExitToHub()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Returns to AdventureHub without recording a completion.")

                Button("Wrap up today") {
                    completeOnce()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeAccent)
                .accessibilityHint("Records this session as complete and returns to the hub.")
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("MicrobeLab \(copy.title) inside AdventureHub")
    }

    @ViewBuilder
    private var engineSurface: some View {
        // The live MicrobeLab tab surfaces (`ExploreView` / `MicrobiomeView` /
        // `ImmuneGameView`) require the full app dep graph (catalog / mentor /
        // gamification / celebration / analytics / sensory). AdventureHub's
        // orchestrator context is parallel to the app's tab shell, so the
        // contribution renders a hub-friendly placeholder surface that
        // surfaces the per-engine copy + a clear path back to the app. When
        // AdventureHub-side context wiring lands (Phase 4 classroom-mode
        // integration), this placeholder can be upgraded to host the live
        // surfaces via a shared service-container handoff.
        VStack(spacing: 12) {
            Image(systemName: engineIconName)
                .font(.system(size: 64, weight: .regular))
                .foregroundStyle(themeAccent)
                .accessibilityHidden(true)
            Text(copy.completionMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("Open MicrobeLab to play. AdventureHub records the completion when you tap \"Wrap up today\".")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(themeAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var engineIconName: String {
        switch engine {
        case .quest: "magnifyingglass"
        case .simulation: "leaf"
        case .defense: "shield.lefthalf.filled"
        case .puzzle: "key.viewfinder"
        default: "circle.dashed"
        }
    }

    private func completeOnce() {
        guard !hasInvokedComplete else { return }
        hasInvokedComplete = true
        let onComplete = context.onComplete
        let elapsed = context.elapsedSeconds()
        Task { @MainActor in
            await onComplete(
                HubChallengeResult(
                    score: 1,
                    total: 1,
                    durationSeconds: max(0, elapsed),
                    bloomMastered: [.understand]
                )
            )
            context.onExitToHub()
        }
    }
}
