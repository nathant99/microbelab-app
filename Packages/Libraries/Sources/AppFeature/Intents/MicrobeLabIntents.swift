import Foundation
import AppIntents
import Models
import Services

/// App Intents for MicrobeLab. Each intent opens the app and switches the
/// active tab via `Services.NavigationCoordinator.shared.requestTab(_:)`.
/// Wired through `MicrobeLabAppShortcuts` so they surface in Siri /
/// Spotlight / Shortcuts without any Info.plist edits — `AppShortcuts`
/// auto-discovery uses runtime metadata, not the bundle plist.
///
/// Trauma-informed posture: the intents never override the kid's session
/// state. They land on a tab; the tab's own view code drives the rest.
/// No special-cased "intent vs tap" logic so the kid (or parent setting up
/// a Shortcut) experiences the same surface either way.
///
/// Why three separate intents instead of one parameterized intent: Apple
/// surfaces each as a distinct top-level Shortcut suggestion, and Siri
/// phrasing reads more naturally when each intent has its own title.
/// Per `Docs/FEATURE_PLAN.md` § Adventure Mode + the maximize-ForgeKit-
/// integration directive — this closes the `ForgeIntents` declared-but-
/// unused gap by promoting the module from `Package.swift` dependency to
/// actively consumed.
///
/// `openAppWhenRun = true` is essential — without it the intent runs
/// headless and the tab switch never reaches a visible surface. The
/// `perform()` method's `IntentResult & OpensIntent` composite return type
/// is iOS 16+'s standard "open the app, then perform the action" pattern.

/// Opens MicrobeLab on the Explore tab (microscope canvas).
public struct OpenMicroscopeIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Microscope"
    public static let description = IntentDescription(
        "Open MicrobeLab on the microscope canvas to explore the microbe world."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestTab(.explore)
        return .result()
    }
}

/// Opens MicrobeLab on the Codex tab (12-microbe character grid).
public struct OpenCodexIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Microbe Codex"
    public static let description = IntentDescription(
        "Open MicrobeLab on the microbe codex to see characters you've met."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestTab(.codex)
        return .result()
    }
}

/// Opens MicrobeLab on the Microbiome tab (gut-ecology simulator). Note:
/// the Microbiome tab is gated behind session 2+ progressive disclosure
/// (`TabDisclosure.showsMicrobiome`). If a kid runs this intent on session
/// 1 the navigation coordinator still surfaces the request; AppRootView
/// applies it only if the Microbiome tab is currently visible, otherwise
/// the request is silently no-opped on the consumer side (graceful
/// fallback so a Shortcut wired today doesn't error out when the kid
/// re-installs or resets). Per `Docs/FEATURE_PLAN.md` § Progressive
/// disclosure.
public struct OpenMicrobiomeIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Microbiome Simulator"
    public static let description = IntentDescription(
        "Open MicrobeLab on the microbiome simulator to feed and observe the gut ecology."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestTab(.microbiome)
        return .result()
    }
}

// MARK: - Phase 3 / Phase 4 sub-surface intents
//
// Deep-link past the Microbiome tab into a specific Phase 3 / Phase 4
// inner surface. Each intent calls `NavigationCoordinator.requestSubSurface`
// which sets BOTH the implied host tab (.microbiome) + the sub-surface
// request; `AppRootView` switches the tab, `MicrobiomeView` flips the
// matching `.navigationDestination(isPresented:)` flag.
//
// Trauma-informed posture: every deep-link target is a Phase 3 / Phase 4
// surface that ships its own ParentalConsentService + ProgressionService
// gate. The intent only requests the navigation; the gate decides whether
// the surface's body content renders. A Shortcut wired today for
// `.diseaseStories` lands on the menu chrome but the per-arc body stays
// `.gatedBehindProgression` or `.gatedBehindConsent` until the canonical
// gates clear — NEVER a backdoor past the gates.

/// Opens MicrobeLab on the Phase 3 Disease Stories menu (lives behind the
/// Microbiome tab's toolbar).
public struct OpenDiseaseStoriesIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Disease Stories"
    public static let description = IntentDescription(
        "Open MicrobeLab on the disease-story arcs menu — gentle handwashing / vaccine / antibiotic / outbreak narratives, gated by parental consent + session progress."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestSubSurface(.diseaseStories)
        return .result()
    }
}

/// Opens MicrobeLab on the Phase 3 Vaccine Explainer (lives behind the
/// Microbiome tab's toolbar).
public struct OpenVaccineExplainerIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Vaccine Explainer"
    public static let description = IntentDescription(
        "Open MicrobeLab on the vaccine mini-explainer — the body's library practicing a new shape ahead of meeting it live."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestSubSurface(.vaccineExplainer)
        return .result()
    }
}

/// Opens MicrobeLab on the Phase 3 Historical Context Cards (lives behind
/// the Microbiome tab's toolbar).
public struct OpenHistoricalContextIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Historical Context"
    public static let description = IntentDescription(
        "Open MicrobeLab on the historical context cards — scientists who watched microbes carefully."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestSubSurface(.historicalContext)
        return .result()
    }
}

/// Opens MicrobeLab on the Phase 4 Global Microbiome Tour (lives behind
/// the Microbiome tab's toolbar).
public struct OpenGlobalMicrobiomeTourIntent: AppIntent {
    public static let title: LocalizedStringResource = "Open Global Microbiome Tour"
    public static let description = IntentDescription(
        "Open MicrobeLab on the global microbiome tour — Yellowstone hot springs, deep-sea vents, your gut, and the soil under your feet."
    )
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        NavigationCoordinator.shared.requestSubSurface(.globalMicrobiomeTour)
        return .result()
    }
}
