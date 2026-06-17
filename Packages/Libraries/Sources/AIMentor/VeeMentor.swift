import Foundation
import FoundationModels
import ForgeAI
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

    /// Optional `CastDialog` actor for the DN-S voicing surface. When non-nil,
    /// `voicedRecallCue(for:daysSinceLastSeen:context:)` dispatches utterances
    /// through the per-cast voice profile so a kid revisiting an "old friend"
    /// microbe hears the cast member's authored voice register instead of the
    /// generic mentor recall line. Wired by `AppRootView` when the
    /// `cast_voicing` experiment flag (PR #173) is `.enabled`. Stays nil for
    /// the default control variant + the legacy call sites unaffected.
    public let castDialog: CastDialog?

    public init(
        microbes: [MicrobeCharacter],
        castDialog: CastDialog? = nil
    ) {
        self.microbes = microbes
        self.castDialog = castDialog
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

    /// Surface one of the microbe's authored voice lines per the DN-S voice
    /// register card. Rotation is deterministic-by-index so a kid revisiting
    /// the codex sees fresh lines without the mentor sounding scripted.
    public func voiceLine(for slug: String, rotation: Int) -> String? {
        guard let microbe = microbe(forSlug: slug) else { return nil }
        guard !microbe.voiceLines.isEmpty else { return microbe.catchphrase }
        let index = abs(rotation) % microbe.voiceLines.count
        return microbe.voiceLines[index]
    }

    /// DN-S voiced recall variant. When `castDialog` is non-nil AND the
    /// microbe's slug is registered against the CastDialog AND CastDialog's
    /// response isn't the safe-ellipsis fallback (`"…"`), returns the
    /// cast-voiced utterance. Otherwise returns the canonical static
    /// `recallCue(for:daysSinceLastSeen:)` so the caller never sees a regression
    /// when voicing is unavailable, the flag is OFF, or FoundationModels is
    /// down.
    ///
    /// Per `Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` step 4:
    /// the voicing path is opt-in via the `cast_voicing` experiment flag.
    /// `AppRootView` wires the `CastDialog` instance + registers profiles
    /// when the flag is `.enabled`; the per-microbe slug-to-profile mapping
    /// is canonical (`MicrobeCastVoiceProfiles.Slug.all` mirrors
    /// `MicrobeCharacter.slug` for the 6 DN-S cast members).
    ///
    /// **Trauma-informed posture preserved**: the trigger is `.greeting`,
    /// which CastDialog's prompt scaffold renders as a warm welcome — never
    /// loss-aversion / "you abandoned us" framing. The output-moderation
    /// pipeline inside CastDialog additionally guards against warfare /
    /// shame / threat language regardless of FoundationModels output.
    public func voicedRecallCue(
        for slug: String,
        daysSinceLastSeen: Int,
        context: CastDialogContext
    ) async -> String? {
        let staticFallback = recallCue(for: slug, daysSinceLastSeen: daysSinceLastSeen)
        guard let castDialog else { return staticFallback }
        let isRegistered = await castDialog.isRegistered(slug)
        guard isRegistered else { return staticFallback }
        let response = await castDialog.respond(
            as: slug,
            trigger: .greeting,
            context: context
        )
        if response == "…" || response.isEmpty {
            return staticFallback
        }
        return response
    }

    /// Warm callback line referencing a microbe the kid has met before. The
    /// `daysSinceLastSeen` is the trauma-safe pivot: same-day reads as
    /// "still hanging around", multi-day reads as "still here when you're
    /// ready" — never "you abandoned us" or loss-aversion framing.
    ///
    /// Returns `nil` when the slug isn't in the catalog so the caller can
    /// fall back to the default mentor copy without surfacing a broken
    /// callback. Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Character
    /// personality" item.
    public func recallCue(for slug: String, daysSinceLastSeen: Int) -> String? {
        guard let microbe = microbe(forSlug: slug) else { return nil }
        let name = microbe.displayName
        switch max(0, daysSinceLastSeen) {
        case 0:
            return "\(name) is still hanging around from earlier today. Want another look?"
        case 1:
            return "Saw \(name) yesterday — they're still here when you're ready."
        case 2...6:
            return "\(name) showed up a few days back. They've been quiet, but they're still around."
        default:
            return "Last time you stopped by, \(name) was around. They're still hanging in."
        }
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

    /// Curriculum-safe static `AdaptiveImmuneHypothesis` for the named
    /// scenario — always available, never blocks. Trauma-safe register
    /// per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture:
    /// shape-matching + recognition framing, never warfare.
    public func fallbackAdaptiveImmuneHypothesis(for scenario: AdaptiveImmuneScenario) -> AdaptiveImmuneHypothesis {
        switch scenario {
        case .firstEncounter:
            return AdaptiveImmuneHypothesis(
                observation: "What shape did your body just meet for the first time?",
                memoryHypothesis: "Usually the body takes a moment to find a matching antibody on a first meet."
            )
        case .matchedShape:
            return AdaptiveImmuneHypothesis(
                observation: "Your antibody fits this shape — what might the body do with that match?",
                memoryHypothesis: "Often the body keeps a note of the matched shape so it recognizes it next time."
            )
        case .recallFromMemory:
            return AdaptiveImmuneHypothesis(
                observation: "Did the body recognize this shape faster than last time?",
                memoryHypothesis: "Memory cells usually let the body match a known shape more quickly on a return visit."
            )
        }
    }

    /// Curriculum-safe static `PublicHealthHypothesis` for the named
    /// scenario — always available, never blocks. Trauma-safe register
    /// per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture +
    /// ADR-016 SAMHSA TIP 57 framing: handwashing as care, vaccines as
    /// library priming, antibiotic recovery as patience, outbreak as
    /// community helpers.
    public func fallbackPublicHealthHypothesis(for scenario: PublicHealthScenario) -> PublicHealthHypothesis {
        switch scenario {
        case .handwashing:
            return PublicHealthHypothesis(
                observation: "What happens to the skin neighborhood after a gentle wash?",
                healthHypothesis: "Often the skin community settles back into a quiet balance — washing is care, not a moral test."
            )
        case .vaccinePriming:
            return PublicHealthHypothesis(
                observation: "What might the B-cell library do with a brand-new shape it has never seen?",
                healthHypothesis: "Usually the body practices recognizing the shape ahead of time — that's how a vaccine helps the library get ready."
            )
        case .antibioticStewardship:
            return PublicHealthHypothesis(
                observation: "After antibiotic care, what do you notice as the microbiome takes time to rebuild?",
                healthHypothesis: "Often the neighborhood comes back slowly, and slow IS wise — patience lets the gentle helpers return."
            )
        case .outbreakRecovery:
            return PublicHealthHypothesis(
                observation: "When the community shifts together, what do you notice the helpers doing?",
                healthHypothesis: "Usually people look after each other — sharing care and quiet attention is how a community holds steady."
            )
        }
    }

    /// Curriculum-safe static `VaccineMechanismCue` for the named scenario —
    /// always available, never blocks. Trauma-safe register per
    /// `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture + ADR-016:
    /// vaccines are the body's library learning a new shape ahead of meeting
    /// it live, never warfare. Pairs with `VaccineExplainerStep` 1:1 via the
    /// enum cases.
    public func fallbackVaccineMechanismCue(for scenario: VaccineMechanismScenario) -> VaccineMechanismCue {
        switch scenario {
        case .introduction:
            return VaccineMechanismCue(
                observation: "What might a vaccine be for the body's library of shapes?",
                librariesHypothesis: "Often a vaccine is a kind helper that brings a new shape early — never a fear hook."
            )
        case .antibodyPriming:
            return VaccineMechanismCue(
                observation: "What might the B-cell library do with a brand-new shape it has not seen yet?",
                librariesHypothesis: "Usually the library practices matching the shape ahead of time so it is ready when the live shape arrives."
            )
        case .memoryFormation:
            return VaccineMechanismCue(
                observation: "After the library practices, what might it keep for next time?",
                librariesHypothesis: "Often the body keeps a small note of the matched shape so it recognizes it more quickly on a return visit."
            )
        case .boosterRationale:
            return VaccineMechanismCue(
                observation: "Why might a second dose help the library remember more steadily?",
                librariesHypothesis: "Usually a booster is patient care — a gentle reminder that helps the note stay clear over time."
            )
        }
    }

    /// Curriculum-safe static `HistoricalContextReflection` for the named
    /// scenario — always available, never blocks. Trauma-safe register per
    /// CQ CONTENT_STYLE_GUIDE.md § 4.5 anti-credentialism gate + ADR-016:
    /// figures framed as patient observers, NEVER hero-myth, NEVER mortality
    /// framing on disease lexicon. Pairs with `HistoricalContextFigure` 1:1
    /// via the enum cases.
    public func fallbackHistoricalContextReflection(for scenario: HistoricalContextScenario) -> HistoricalContextReflection {
        switch scenario {
        case .pasteur:
            return HistoricalContextReflection(
                noticing: "What might Louis Pasteur have noticed across many quiet hours at his lab notebook?",
                kidScientistTakeaway: "Often the careful notebook habit is the science — you can keep one too."
            )
        case .koch:
            return HistoricalContextReflection(
                noticing: "How might Robert Koch have figured out which microbe paired with which pattern?",
                kidScientistTakeaway: "Usually patient pattern noticing is how the answer arrives — small careful steps over time."
            )
        case .salk:
            return HistoricalContextReflection(
                noticing: "What might a community discover when many people share care with each other?",
                kidScientistTakeaway: "Often public-health wonder comes from a lot of people doing small careful things together."
            )
        case .marshall:
            return HistoricalContextReflection(
                noticing: "What might a quiet observer notice that the textbooks have not caught up to yet?",
                kidScientistTakeaway: "Usually a long noticing plus a small careful experiment is enough — that is real science."
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

    /// Generate a Socratic `AdaptiveImmuneHypothesis` for the named
    /// scenario. Falls back to the static authored content when the model
    /// is unavailable. Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed
    /// Design Posture, the prompt explicitly forbids warfare framing —
    /// adaptive immunity surfaces as the body's library of shapes.
    public func adaptiveImmuneHypothesis(for scenario: AdaptiveImmuneScenario) async -> AdaptiveImmuneHypothesis {
        guard isAvailable, let session = makeSession() else {
            return fallbackAdaptiveImmuneHypothesis(for: scenario)
        }
        do {
            let response = try await session.respond(
                to: """
                The kid just hit the \(scenario.rawValue) beat in the B-cell \
                antibody-matching minigame. Compose an open-ended observation \
                question framed around SHAPE-MATCHING and recognition (never \
                warfare — no "fight" / "attack" / "destroy" / "kill" / "war" / \
                "enemy" / "battle"), and one testable prediction about how \
                memory cells respond on re-exposure. Age 9-14 register, \
                hedging language only ("often", "usually", "many").
                """,
                generating: AdaptiveImmuneHypothesis.self
            )
            return response.content
        } catch {
            return fallbackAdaptiveImmuneHypothesis(for: scenario)
        }
    }

    /// Generate a Socratic `PublicHealthHypothesis` for the named scenario.
    /// Falls back to the static authored content when the model is
    /// unavailable. Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design
    /// Posture + ADR-016 SAMHSA TIP 57 framing, the prompt explicitly forbids
    /// warfare + shame + threat framing — public-health pedagogy surfaces
    /// as care + library + patience + community.
    public func publicHealthHypothesis(for scenario: PublicHealthScenario) async -> PublicHealthHypothesis {
        guard isAvailable, let session = makeSession() else {
            return fallbackPublicHealthHypothesis(for: scenario)
        }
        let registerHint: String
        switch scenario {
        case .handwashing:
            registerHint = "handwashing is CARE for the microbiome neighborhood, not a moral test"
        case .vaccinePriming:
            registerHint = "vaccines are the body's LIBRARY learning a new shape ahead of time"
        case .antibioticStewardship:
            registerHint = "antibiotic recovery is PATIENCE — the microbiome rebuilds slowly and slow IS wise"
        case .outbreakRecovery:
            registerHint = "outbreak recovery is COMMUNITY — helpers share care and attention"
        }
        do {
            let response = try await session.respond(
                to: """
                The kid just hit the \(scenario.rawValue) beat in a Phase 3 \
                disease-story arc. Frame: \(registerHint). Compose an open- \
                ended observation question framed around CARE + CURIOSITY + \
                COMMUNITY (never warfare — no "fight" / "attack" / "destroy" / \
                "kill" / "war" / "enemy" / "battle" / "weapon"; never shame — \
                no "should" / "must" / "failure" / "behind"; never threat — \
                no "scary" / "panic" / "germ" / "horror" / "danger"), and \
                one testable prediction framed as ecology + recovery. Age \
                9-14 register, hedging language only ("often", "usually", \
                "many").
                """,
                generating: PublicHealthHypothesis.self
            )
            return response.content
        } catch {
            return fallbackPublicHealthHypothesis(for: scenario)
        }
    }

    /// Generate a Socratic `VaccineMechanismCue` for the named vaccine-explainer
    /// step. Falls back to the static authored content when the model is
    /// unavailable. Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design
    /// Posture + ADR-016, the prompt explicitly forbids warfare framing —
    /// vaccines surface as the body's library learning a new shape ahead of
    /// meeting it live.
    public func vaccineMechanismCue(for scenario: VaccineMechanismScenario) async -> VaccineMechanismCue {
        guard isAvailable, let session = makeSession() else {
            return fallbackVaccineMechanismCue(for: scenario)
        }
        let stepHint: String
        switch scenario {
        case .introduction:
            stepHint = "the gentle introduction step — vaccines as a kind helper, never a fear hook"
        case .antibodyPriming:
            stepHint = "the antibody-priming step — the B-cell library practices matching a new shape ahead of time"
        case .memoryFormation:
            stepHint = "the memory-formation step — the body keeps a note of the matched shape so it recognizes it next time"
        case .boosterRationale:
            stepHint = "the booster-rationale step — a second dose is patient care that helps the note stay clear"
        }
        do {
            let response = try await session.respond(
                to: """
                The kid just stepped to \(stepHint) in the Phase 3 vaccine \
                mini-explainer. Compose an open-ended observation question \
                framed around the body's LIBRARY learning a shape (never \
                warfare — no "fight" / "attack" / "destroy" / "kill" / "war" / \
                "enemy" / "battle" / "weapon"; never fear-induction — no \
                "scary" / "danger" / "panic" / "germ" / "horror"; never \
                shame — no "should" / "must" / "failure"), and one testable \
                prediction about how the antibody library or memory cells \
                respond, framed as care + curiosity. Age 9-14 register, \
                hedging language only ("often", "usually", "many").
                """,
                generating: VaccineMechanismCue.self
            )
            return response.content
        } catch {
            return fallbackVaccineMechanismCue(for: scenario)
        }
    }

    /// Generate a Socratic `HistoricalContextReflection` for the named figure.
    /// Falls back to the static authored content when the model is
    /// unavailable. Per CQ CONTENT_STYLE_GUIDE.md § 4.5 anti-credentialism
    /// gate + ADR-016, the prompt explicitly forbids hero-myth + mortality +
    /// warfare framing — figures surface as patient observers taking small
    /// careful steps the kid can also take.
    public func historicalContextReflection(for scenario: HistoricalContextScenario) async -> HistoricalContextReflection {
        guard isAvailable, let session = makeSession() else {
            return fallbackHistoricalContextReflection(for: scenario)
        }
        let figureHint: String
        switch scenario {
        case .pasteur:
            figureHint = "Louis Pasteur — patient experimental-notebook register, NEVER the rabid-dog drama"
        case .koch:
            figureHint = "Robert Koch — pattern-noticing methodology spine, NEVER mortality counting"
        case .salk:
            figureHint = "Jonas Salk — community made polio rare through care, NEVER panic recall"
        case .marshall:
            figureHint = "Barry Marshall — long noticing plus small careful experiments overturned consensus, NEVER bravado"
        }
        do {
            let response = try await session.respond(
                to: """
                The kid just opened the historical context card for \
                \(figureHint). Compose an open-ended question naming what the \
                figure noticed across long careful observation (never hero- \
                myth — no "genius" / "saved millions" / "legendary"; never \
                mortality framing — no "killed" / "died" / "deadly"; never \
                warfare lexicon — no "fight" / "battle" / "weapon"), and one \
                kid-scientist takeaway the kid can carry into their own \
                observation today, framed as small careful steps. Age 9-14 \
                register, hedging language only ("often", "usually", "many").
                """,
                generating: HistoricalContextReflection.self
            )
            return response.content
        } catch {
            return fallbackHistoricalContextReflection(for: scenario)
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
