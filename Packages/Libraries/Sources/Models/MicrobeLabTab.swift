import Foundation

/// Stable identifier for each top-level tab in `AppRootView`'s `TabView`.
/// Used as the `value:` parameter on `Tab(_:systemImage:value:)` so the
/// system can drive tab selection deterministically — both for the user's
/// own taps AND for App Intents launching the app via Siri / Spotlight /
/// Shortcuts (per `Services.NavigationCoordinator` + AppFeature `Intents/`).
///
/// Stable raw values matter: App Intents and analytics carry the slug
/// across launches, so renaming a case would silently drop existing
/// Shortcut wirings. The slugs are deliberately lower-camel-snake so they
/// match the analytics event names already in `MicrobeLabAnalyticsEvent`.
public nonisolated enum MicrobeLabTab: String, Hashable, CaseIterable, Sendable, Codable {
    case explore = "explore"
    case codex = "codex"
    case microbiome = "microbiome"
    case progress = "progress"
    case profile = "profile"
}
