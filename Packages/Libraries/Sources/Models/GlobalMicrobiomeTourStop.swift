import Foundation

/// One of the four canonical Phase 4 global-microbiome tour stops scoped in
/// `Docs/TECHNICAL_DESIGN.md` § Phase 4 + `Docs/FEATURE_PLAN.md` § Phase 4.
///
/// **Important**: prose content for these stops is NOT authored in-app. Every
/// stop ships with `authoring == .placeholder` until external reviewer signs
/// off per `.claude/rules/distributed-narrative.md` § cultural-sensitivity
/// gates (Indigenous TEK / land-use framing for Yellowstone + deep-sea
/// exploration framing) and ADR-016. The catalog ships the metadata + cast
/// references + gate keys so the structural scaffold can be wired
/// (`ProgressionService.global-microbiome-tour` gate from PR #137) without
/// committing to prose that has not been reviewed.
public nonisolated enum GlobalMicrobiomeTourStop: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Yellowstone hot spring — extremophile archaea + thermophilic bacteria
    /// thriving in geothermal water. Cultural-respect register required:
    /// Yellowstone sits on land with deep Indigenous history (Crow, Eastern
    /// Shoshone, Northern Arapaho, Bannock, Blackfeet, Confederated Salish-
    /// Kootenai); any prose must credit Indigenous knowledge of these
    /// ecosystems explicitly per `.claude/rules/distributed-narrative.md`
    /// § cultural-sensitivity gates.
    case yellowstoneHotSpring

    /// Deep-sea hydrothermal vent — chemosynthetic ecosystem where microbes
    /// make food from sulfide chemistry instead of sunlight. Frames the deep
    /// sea as a thriving system NOT a dark scary place; the vent community is
    /// a wonder of adaptation.
    case deepSeaVent

    /// Human gut — the kid's most-familiar microbiome surface. Bridges back
    /// to Phase 1 / 2 ecology scenes so the kid sees how the same ecology
    /// math applies across radically different habitats. Cohort: Lacto +
    /// Akker + Bifido (the canonical Phase 1 cast).
    case humanGut

    /// Soil underground — decomposer ecology + nitrogen fixation + the
    /// thriving forest-floor community. Bridges to bioforge / ecosphere per
    /// the cross-portfolio cluster framing (cast: Loam, Nodu, Halo). Frames
    /// soil as a thriving system NEVER "dirt".
    case soilUnderground

    public var id: String { rawValue }

    /// Kid-readable title; safe to surface in menus while the body content
    /// is `.placeholder` because the title alone doesn't promise anything
    /// the kid can't already infer from the menu chrome.
    public var displayTitle: String {
        switch self {
        case .yellowstoneHotSpring: return "Yellowstone hot springs"
        case .deepSeaVent:          return "Deep-sea vents"
        case .humanGut:             return "Inside the gut"
        case .soilUnderground:      return "The quiet underground"
        }
    }

    /// Stable curriculum hook. NGSS-aligned framing; used by the gating
    /// service to decide which curricular thread the kid is being scaffolded
    /// toward when the global-microbiome-tour gate flips open.
    public var primitive: String {
        switch self {
        case .yellowstoneHotSpring:
            return "thermophilic ecosystem + Indigenous TEK"
        case .deepSeaVent:
            return "chemosynthesis + extremophile adaptation"
        case .humanGut:
            return "host-microbiome mutualism (Phase 1/2 review at world scale)"
        case .soilUnderground:
            return "decomposer ecology + nitrogen fixation"
        }
    }

    /// Which gate this stop lives behind. All four ride the
    /// `global-microbiome-tour` gate from `ProgressionService` (PR #137) —
    /// 8 sessions + 4 distinct ecologies visited.
    public var gateID: String {
        "global-microbiome-tour"
    }

    /// Featured cast members for this stop. Slugs reference the 24-microbe
    /// catalog (Phase 1 base + Phase 2 expansion + Phase 4 extremophile pack
    /// from PR #151). Display layer renders these as portrait chips with
    /// taps that dispatch to the codex card.
    public var featuredMicrobeSlugs: [String] {
        switch self {
        case .yellowstoneHotSpring: return ["crenarch", "therm"]
        case .deepSeaVent:          return ["crenarch", "baro"]
        case .humanGut:             return ["lacto", "akker", "bifido"]
        case .soilUnderground:      return ["loam", "nodu", "halo"]
        }
    }
}

/// Per-stop authoring state. The `.placeholder` state is load-bearing: the
/// catalog can ship all four stops structurally while keeping prose content
/// reviewer-blocked. Consuming views MUST gate rendering on
/// `authoring == .reviewerSignedOff` so the kid never sees draft prose.
public nonisolated enum GlobalMicrobiomeTourAuthoring: String, Codable, Sendable, CaseIterable {
    /// Structural placeholder — title + primitive + cast references only. No
    /// prose. The menu surfaces a "Coming soon" affordance instead of the
    /// stop body. This is the default for every stop in Phase 4 rounds
    /// until reviewer-signoff lands.
    case placeholder

    /// Draft prose authored but NOT yet reviewer-signed-off. Visible to
    /// the implementing session for review; views still surface the
    /// "Coming soon" affordance until `.reviewerSignedOff`.
    case draftAwaitingReview

    /// Reviewer-signed-off prose, kid-safe to render. Per ADR-016 +
    /// `.claude/rules/distributed-narrative.md` § cultural-sensitivity gates
    /// the labsmith reviewer pathway counts as signoff for the cultural-
    /// respect axis; per-stop reviewer signoff follows the same pathway.
    case reviewerSignedOff
}

/// A scaffolded global-microbiome-tour stop record. Carries metadata + cast
/// references + gate keys + authoring state. Prose body lives in the
/// consuming view layer (when authored) — this record stays minimal so the
/// catalog can grow without inflating value-type surfaces. Mirrors the
/// `DiseaseStoryArcRecord` shape from PR #141.
public nonisolated struct GlobalMicrobiomeTourStopRecord: Codable, Sendable, Equatable, Identifiable {
    public let stop: GlobalMicrobiomeTourStop
    public let authoring: GlobalMicrobiomeTourAuthoring

    public var id: String { stop.rawValue }
    public var displayTitle: String { stop.displayTitle }
    public var primitive: String { stop.primitive }
    public var gateID: String { stop.gateID }
    public var featuredMicrobeSlugs: [String] { stop.featuredMicrobeSlugs }

    public init(
        stop: GlobalMicrobiomeTourStop,
        authoring: GlobalMicrobiomeTourAuthoring = .placeholder
    ) {
        self.stop = stop
        self.authoring = authoring
    }
}
