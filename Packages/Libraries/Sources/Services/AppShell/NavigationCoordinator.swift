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

    /// When non-nil, indicates an App Intent (or other system surface) has
    /// requested the app navigate to a specific Phase 3 / Phase 4 sub-
    /// surface that lives behind a top-level tab's toolbar. The matching
    /// `requestedTab` is also set so `AppRootView` can switch the tab on
    /// the same observation; the sub-surface is then consumed by the host
    /// view (`MicrobiomeView` for the current 4 canonical surfaces) which
    /// flips its `.navigationDestination(isPresented:)` flag.
    ///
    /// Per `Docs/FEATURE_PLAN.md` § Adventure Mode + the maximize-ForgeKit-
    /// integration directive: this is the deep-link routing surface that
    /// lets App Intents (Siri / Spotlight / Shortcuts) land the kid (or
    /// parent setting up a Shortcut) directly on a Phase 3 / Phase 4
    /// surface in one step. No Info.plist edits required — the
    /// AppShortcutsProvider discovery uses runtime metadata.
    ///
    /// Trauma-informed posture: this field carries a navigation REQUEST
    /// only. The per-surface ParentalConsentService + ProgressionService
    /// gates still decide whether the surface's body content renders. The
    /// intent NEVER backdoors past the canonical gates.
    public private(set) var requestedSubSurface: MicrobeLabSubSurface?

    public init() {}

    /// Set the requested tab. Same value as the current value still
    /// triggers the observer (the kid may have manually navigated since
    /// the last request); `AppRootView` does the redundancy check.
    public func requestTab(_ tab: MicrobeLabTab) {
        DebugLog.lifecycle("NavigationCoordinator requestTab \(tab.rawValue)")
        requestedTab = tab
    }

    /// Set the requested sub-surface. Implies + sets the matching `hostTab`
    /// so `AppRootView` can switch the tab on the same observation cycle;
    /// the host view (`MicrobiomeView` for the current 4 canonical
    /// surfaces) consumes the sub-surface field to push the inner
    /// navigation. Idempotent — same value re-triggers the observer so
    /// re-firing the same intent after the kid manually navigated still
    /// re-routes cleanly.
    ///
    /// Per `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` + the auto-cycle
    /// pre-approval: the routing extension is SPM-only — no entitlement
    /// provisioning required.
    public func requestSubSurface(_ surface: MicrobeLabSubSurface) {
        DebugLog.lifecycle("NavigationCoordinator requestSubSurface \(surface.rawValue) (hostTab=\(surface.hostTab.rawValue))")
        requestedTab = surface.hostTab
        requestedSubSurface = surface
    }

    /// Clear the pending tab request after the consumer has applied it.
    /// Idempotent — calling when already nil is a no-op. Does NOT clear
    /// the sub-surface request; the host view is responsible for clearing
    /// that via `clearSubSurfaceRequest()` AFTER it has flipped its
    /// `.navigationDestination(isPresented:)` flag. This two-step ordering
    /// matters because `AppRootView` clears the tab request as soon as the
    /// tab switch lands, but the host view's `.navigationDestination` flag
    /// needs the sub-surface field to survive at least until the host
    /// view's `.onChange` observer fires.
    public func clearRequest() {
        requestedTab = nil
    }

    /// Clear the pending sub-surface request after the host view has
    /// applied it. Idempotent — calling when already nil is a no-op.
    public func clearSubSurfaceRequest() {
        requestedSubSurface = nil
    }
}
