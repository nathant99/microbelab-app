import Foundation
import FoundationModels
import Models

/// Cilia (formerly Vee) — the Socratic mentor for MicrobeLab.
///
/// Per `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` the
/// mentor's player-facing name is **Cilia** to resolve the Dr. Quark hard
/// collision with AdventureHub Wave 27. The class name stays `VeeMentor` to
/// match the original spec; the player-facing display string lives in
/// `displayName`.
///
/// Per `.claude/rules/foundationmodels.md`:
/// - `SystemLanguageModel.default` is held as a stored property; availability
///   is derived via the `isAvailable` computed property
/// - `LanguageModelSession` is lazy + reused across requests
/// - Every async `@Generable` call has a synchronous static fallback so the
///   UI never blocks on FoundationModels availability or background-unload
///
/// Per `.claude/rules/ai-content.md`, curriculum fact text is authored static
/// content sourced from each `MicrobeCharacter.factCard`. The AI surface is
/// reserved for OPEN-ENDED Socratic prompts that scaffold inquiry — never
/// for factual claims the kid will take as authoritative.
@MainActor
public final class VeeMentor {
    public static let displayName = "Cilia"

    public let microbes: [MicrobeCharacter]
    private let model = SystemLanguageModel.default
    @ObservationIgnored private var cachedSession: LanguageModelSession?

    public init(microbes: [MicrobeCharacter]) {
        self.microbes = microbes
    }

    /// Whether the on-device model is ready to serve generation requests.
    /// Callers SHOULD use this to decide whether to await the async accessors
    /// or fall straight to the static fallback path.
    public var isAvailable: Bool {
        model.availability == .available
    }

    // MARK: - Static (synchronous) accessors

    /// Returns the static catchphrase for the named microbe — no AI call.
    /// Used for first-meet events; the AI surface activates on follow-up
    /// Socratic prompts via `microbeFact(for:)`.
    public func catchphrase(for slug: String) -> String? {
        microbe(forSlug: slug)?.catchphrase
    }

    /// Returns the curriculum-mapped fact card for the named microbe.
    /// Static content per `.claude/rules/ai-content.md` — never AI-generated.
    public func factCard(for slug: String) -> String? {
        microbe(forSlug: slug)?.factCard
    }

    // MARK: - Static fallbacks for every @Generable

    /// Curriculum-safe static `MicrobeFact` — always available, never blocks.
    /// Returns `nil` only when the slug isn't in the catalog.
    public func fallbackMicrobeFact(for slug: String) -> MicrobeFact? {
        guard let microbe = microbe(forSlug: slug) else { return nil }
        let prompt = "What do you notice about \(microbe.displayName)?"
        return MicrobeFact(socraticPrompt: prompt, factBody: microbe.factCard)
    }

    /// Curriculum-safe static `ZoomCue` — always available, never blocks.
    public func fallbackZoomCue(for tier: ZoomTier) -> ZoomCue {
        switch tier {
        case .unaided:
            return ZoomCue(
                reaction: "Start with what your eye can see.",
                lookForHint: "Shapes and colors."
            )
        case .light:
            return ZoomCue(
                reaction: "A light microscope opens up a hidden city.",
                lookForHint: "Round shapes that wiggle."
            )
        case .fluorescence:
            return ZoomCue(
                reaction: "Now the cells glow — look for outlines.",
                lookForHint: "Glowing rings around the cells."
            )
        case .electron:
            return ZoomCue(
                reaction: "Welcome to the very, very tiny.",
                lookForHint: "Tiny ridges on the cell wall."
            )
        }
    }

    /// Curriculum-safe static `EcologyHypothesis` — always available, never blocks.
    public func fallbackEcologyHypothesis(for mode: FeedingMode) -> EcologyHypothesis {
        switch mode {
        case .fiber:
            return EcologyHypothesis(
                observation: "What might happen to fiber-loving microbes here?",
                hypothesis: "Bifido often grows when you pick fiber."
            )
        case .sugar:
            return EcologyHypothesis(
                observation: "Who tends to show up when sugar arrives?",
                hypothesis: "Yeast usually grows quickly on sugar."
            )
        case .balanced:
            return EcologyHypothesis(
                observation: "Does a balanced mix help different microbes share space?",
                hypothesis: "Many microbes hold steady together when food is balanced."
            )
        case .none:
            return EcologyHypothesis(
                observation: "What happens when no food arrives for a while?",
                hypothesis: "Most populations slowly shrink — some hardy ones stay."
            )
        }
    }

    // MARK: - Async (FoundationModels) accessors

    /// Generate a Socratic `MicrobeFact` for the named microbe. Falls back to
    /// the static authored content when the model is unavailable, the call
    /// fails, or the slug is unknown.
    public func microbeFact(for slug: String) async -> MicrobeFact? {
        guard let microbe = microbe(forSlug: slug) else { return nil }
        guard isAvailable, let session = makeSession() else {
            return fallbackMicrobeFact(for: slug)
        }
        do {
            let response = try await session.respond(
                to: """
                Compose a one-sentence open-ended Socratic question about \
                \(microbe.displayName) (a \(microbe.kingdom.rawValue) that lives in \
                the \(microbe.preferredEnvironment.rawValue)). Then write a two-sentence \
                curriculum fact using hedging language ("often", "usually", "many") — \
                avoid absolute claims. Age 9-14 register.
                """,
                generating: MicrobeFact.self
            )
            return response.content
        } catch {
            return fallbackMicrobeFact(for: slug)
        }
    }

    /// Generate a Socratic `ZoomCue` for the named tier. Falls back to the
    /// static authored content when the model is unavailable.
    public func zoomCue(for tier: ZoomTier) async -> ZoomCue {
        guard isAvailable, let session = makeSession() else {
            return fallbackZoomCue(for: tier)
        }
        do {
            let response = try await session.respond(
                to: """
                The kid just snapped the microscope to the \(tier.displayLabel) tier \
                (\(tierDescription(tier))). Compose a warm one-sentence reaction with \
                no exclamation points, and a single phrase telling them what to look \
                for. Age 9-14 register.
                """,
                generating: ZoomCue.self
            )
            return response.content
        } catch {
            return fallbackZoomCue(for: tier)
        }
    }

    /// Generate a Socratic `EcologyHypothesis` for the given feeding mode.
    /// Falls back to the static authored content when the model is unavailable.
    public func ecologyHypothesis(for mode: FeedingMode) async -> EcologyHypothesis {
        guard isAvailable, let session = makeSession() else {
            return fallbackEcologyHypothesis(for: mode)
        }
        do {
            let response = try await session.respond(
                to: """
                The kid just chose the \(mode.rawValue) feeding mode for the gut \
                microbiome simulator. Compose an open-ended observation question and \
                one testable prediction they can verify by watching the simulator. \
                Age 9-14 register, hedged language only.
                """,
                generating: EcologyHypothesis.self
            )
            return response.content
        } catch {
            return fallbackEcologyHypothesis(for: mode)
        }
    }

    // MARK: - Internals

    private func microbe(forSlug slug: String) -> MicrobeCharacter? {
        microbes.first { $0.slug == slug }
    }

    private func makeSession() -> LanguageModelSession? {
        if let cachedSession {
            return cachedSession
        }
        guard model.availability == .available else { return nil }
        let session = LanguageModelSession(
            instructions: """
            You are Cilia, a calm Socratic mentor in MicrobeLab — a microbiology \
            adventure for kids ages 9-14. Frame everything around wonder and \
            agency, not fear. Most microbes help; only a few cause illness. Use \
            hedging language ("often", "usually") whenever you state a fact. \
            Never reference COVID or pandemic-era pathogens.
            """
        )
        cachedSession = session
        return session
    }

    private func tierDescription(_ tier: ZoomTier) -> String {
        switch tier {
        case .unaided: return "naked-eye view"
        case .light: return "light microscope, 100× magnification"
        case .fluorescence: return "fluorescence microscope, 1 000× magnification"
        case .electron: return "electron microscope, 10 000× magnification"
        }
    }
}
