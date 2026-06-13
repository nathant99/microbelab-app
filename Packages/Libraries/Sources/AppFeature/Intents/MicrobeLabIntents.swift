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
