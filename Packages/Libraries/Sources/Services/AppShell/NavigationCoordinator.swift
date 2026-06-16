import Foundation
import Observation
import Models

/// Single MainActor-isolated `@Observable` coordinator that brokers
/// requests to switch the active tab in `AppRootView`'s `TabView`. The
/// canonical caller is an App Intent (Siri / Spotlight / Shortcuts) — the
/// intent's `perform()` method sets `requestedTab` and `AppRootView`'s
/// `.onChange(of:)` observer reacts by updating its own `@State
/// selectedTab` + calling `clearRequest()`.
///
/// Why a shared singleton: App Intents run on a system-driven `@MainActor`
/// context that doesn't have access to the view's `@State`. They need a
/// stable side-channel to talk to the running app. The singleton is the
/// minimum-overhead pattern that matches Apple's reference impls for App
/// Intents that drive in-app navigation. The shared instance is created
/// lazily and lives for the process lifetime; nothing leaks across
/// sessions because the app process restarts between cold launches.
///
/// Trauma-informed posture: the coordinator does NOT auto-record analytics
/// or fire haptics on intent-driven tab switches. The kid (or parent
/// configuring a Shortcut) is the one driving the navigation; the existing
/// per-tab observers (e.g., `ExploreView.onAppear` recording rare-microbe
/// sightings) still fire because the tab change reaches the same code
/// paths a manual tap would. No special-cased "intent vs tap" logic — same
/// tab, same behavior.
@MainActor
@Observable
public final class NavigationCoordinator {
    /// Process-wide shared instance. App Intents reach for this directly
    /// because they have no other path to the running app. View code
    /// receives it through dependency injection so tests can substitute
    /// an isolated instance.
    public static let shared = NavigationCoordinator()

    /// When non-nil, indicates an App Intent (or other system surface) has
    /// requested the app navigate to a specific tab. `AppRootView`'s
    /// `.onChange(of:)` observer reads this, applies it to its own
    /// `selectedTab`, then calls `clearRequest()` so the same intent fired
    /// again later (e.g., after the kid manually navigated elsewhere)
    /// re-applies cleanly.
    public private(set) var requestedTab: MicrobeLabTab?

    public init() {}

    /// Set the requested tab. Same value as the current value still
    /// triggers the observer (the kid may have manually navigated since
    /// the last request); `AppRootView` does the redundancy check.
    public func requestTab(_ tab: MicrobeLabTab) {
        DebugLog.lifecycle("NavigationCoordinator requestTab \(tab.rawValue)")
        requestedTab = tab
    }

    /// Clear the pending request after the consumer has applied it.
    /// Idempotent — calling when already nil is a no-op.
    public func clearRequest() {
        requestedTab = nil
    }
}
