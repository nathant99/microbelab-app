import Foundation

/// Stable identifier for a Phase 3 / Phase 4 sub-surface that lives behind
/// the Microbiome tab's toolbar (Disease Stories arcs / Vaccine Explainer /
/// Historical Context Cards / Global Microbiome Tour). Used by App Intents
/// (Siri / Spotlight / Shortcuts) + `Services.NavigationCoordinator` to
/// deep-link past the Microbiome tab into a specific inner surface in one
/// shot — the kid (or parent setting up a Shortcut) doesn't have to tap
/// through the tab + the toolbar.
///
/// Stable raw values matter: App Intents carry the slug across launches, so
/// renaming a case would silently drop existing Shortcut wirings. Slugs
/// follow lower-camel so they match the existing `MicrobeLabTab` raw-value
/// register + the analytics-event-name conventions in MicrobeLabAnalyticsEvent.
///
/// Per `Docs/FEATURE_PLAN.md` § Adventure Mode + the maximize-ForgeKit-
/// integration directive: deep-link sub-surface routing closes the gap
/// between AppIntents framework's tab-level surfaces (already shipped in
/// PR pulling these into Siri) and the inner Phase 3 / Phase 4 surfaces
/// (which previously required the kid to first land on Microbiome + then
/// tap the toolbar). No Info.plist edits required — AppShortcutsProvider
/// discovery uses runtime metadata.
///
/// Trauma-informed posture: every deep-link target is a Phase 3 / Phase 4
/// surface that itself ships its own ParentalConsentService + ProgressionService
/// gate; the intent only requests the navigation, the gate decides whether
/// the surface actually renders the body content. A Shortcut wired today
/// for `.diseaseStories` lands on the menu chrome but the per-arc body
/// stays `.gatedBehindProgression` or `.gatedBehindConsent` until the
/// canonical gates clear — never a backdoor past the gates.
public nonisolated enum MicrobeLabSubSurface: String, Hashable, CaseIterable, Sendable, Codable {
    /// Phase 3 disease-story arcs menu (`AppFeature/Engagement/DiseaseStoryArcView`).
    /// Lives behind the Microbiome tab's toolbar; implies the Microbiome
    /// tab is the target when routed via App Intent.
    case diseaseStories = "diseaseStories"

    /// Phase 3 vaccine mini-explainer (`AppFeature/Engagement/VaccineExplainerView`).
    /// Lives behind the Microbiome tab's toolbar.
    case vaccineExplainer = "vaccineExplainer"

    /// Phase 3 historical context cards (`AppFeature/Engagement/HistoricalContextCardsView`).
    /// Lives behind the Microbiome tab's toolbar.
    case historicalContext = "historicalContext"

    /// Phase 4 global-microbiome tour (`AppFeature/GlobalMicrobiomeTourView`).
    /// Lives behind the Microbiome tab's toolbar.
    case globalMicrobiomeTour = "globalMicrobiomeTour"

    /// The top-level tab this sub-surface lives behind. All four canonical
    /// Phase 3 / Phase 4 surfaces live behind the Microbiome tab; this
    /// property exists so the routing layer can ask the sub-surface where
    /// it belongs without hard-coding the answer at every call site.
    public var hostTab: MicrobeLabTab {
        switch self {
        case .diseaseStories,
             .vaccineExplainer,
             .historicalContext,
             .globalMicrobiomeTour:
            return .microbiome
        }
    }

    /// Kid-readable title; used by App Intents for the Siri phrase.
    public var displayTitle: String {
        switch self {
        case .diseaseStories:        return "Disease Stories"
        case .vaccineExplainer:      return "Vaccine Explainer"
        case .historicalContext:     return "Historical Context"
        case .globalMicrobiomeTour:  return "Global Microbiome Tour"
        }
    }
}
