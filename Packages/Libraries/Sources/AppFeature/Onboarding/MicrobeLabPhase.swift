import Foundation
import ForgeNavigation

/// Canonical phase enum for the MicrobeLab pre-tab-shell journey. Conforms
/// to `ForgeNavigation.AppPhase` so future nav-grid or `ForgePhaseRouter`
/// surfaces can consume the same value type the conditional-rendering
/// `Group` block in `AppRootView` currently models.
///
/// The phases align with the gating order in `AppRootView.body`:
/// 1. `.parentHandoff` — parent confirms content comfort + session cap
///    BEFORE the kid sees the microscope onboarding. Gated on
///    `ParentHandoffStore.hasCompletedHandoff`.
/// 2. `.kidOnboarding` — 5-step kid-facing onboarding (welcome → first
///    zoom-in → meet first microbe → first observation → first quiz).
///    Gated on `OnboardingStore.hasCompletedOnboarding`.
/// 3. `.loadingCatalog` — bundled catalog bootstrap in flight.
/// 4. `.tabShell` — the 5-tab `MicrobeLabTab` shell. Steady-state.
/// 5. `.catalogFailure(message:)` — fall-through diagnostic surface when
///    the bundled catalog fails to load.
///
/// Per `.claude/rules/state-machines.md` § Enum-Based State (Navigation &
/// Exclusive Modes) + `.claude/rules/concurrency.md` (nonisolated value
/// type so `Sendable & Hashable` conformances pick up the right
/// isolation under default-MainActor + InferIsolatedConformances).
public nonisolated enum MicrobeLabPhase: AppPhase, Sendable {
    case parentHandoff
    case kidOnboarding
    case loadingCatalog
    case tabShell
    case catalogFailure(message: String)

    /// Stable raw-value-style slug for analytics / debug-log grep. Kept
    /// `lowercase_snake_case` for grep consistency across the portfolio.
    public var slug: String {
        switch self {
        case .parentHandoff: return "parent_handoff"
        case .kidOnboarding: return "kid_onboarding"
        case .loadingCatalog: return "loading_catalog"
        case .tabShell: return "tab_shell"
        case .catalogFailure: return "catalog_failure"
        }
    }

    // MARK: - AppPhase

    public var layoutStrategy: PhaseLayoutStrategy {
        switch self {
        case .parentHandoff, .kidOnboarding, .catalogFailure:
            return .contentConstrained
        case .loadingCatalog:
            return .adaptive
        case .tabShell:
            return .fullScreen
        }
    }

    /// Phases never surface as sidebar items — the app is a 5-tab
    /// `TabView` shell, not a sidebar-navigated phase router. The
    /// conformance is structural so future ForgePhaseRouter consumers
    /// can use the phase enum verbatim.
    public var showsInSidebar: Bool { false }

    public var displayName: String {
        switch self {
        case .parentHandoff: return "Parent Handoff"
        case .kidOnboarding: return "Welcome"
        case .loadingCatalog: return "Loading"
        case .tabShell: return "MicrobeLab"
        case .catalogFailure: return "Couldn't Load Catalog"
        }
    }

    public var systemImage: String {
        switch self {
        case .parentHandoff: return "person.2"
        case .kidOnboarding: return "hand.wave"
        case .loadingCatalog: return "hourglass"
        case .tabShell: return "microscope"
        case .catalogFailure: return "exclamationmark.triangle"
        }
    }
}

public extension MicrobeLabPhase {
    /// Derive the current phase from store state. Mirrors the
    /// conditional-rendering `Group` block in `AppRootView.body` 1:1 so
    /// the value type can be threaded into analytics + debug logs from
    /// outside the view body without re-implementing the gating logic.
    ///
    /// Order: parent handoff → kid onboarding → loading catalog → tab
    /// shell. `catalogFailure` short-circuits the tail when present.
    static func resolve(
        parentHandoffCompleted: Bool,
        kidOnboardingCompleted: Bool,
        catalogLoaded: Bool,
        catalogFailureMessage: String?
    ) -> MicrobeLabPhase {
        if !parentHandoffCompleted {
            return .parentHandoff
        }
        if !kidOnboardingCompleted {
            return .kidOnboarding
        }
        if let message = catalogFailureMessage {
            return .catalogFailure(message: message)
        }
        if catalogLoaded {
            return .tabShell
        }
        return .loadingCatalog
    }
}

/// Canonical startup gate IDs the AppRootView gating enforces today. Pure
/// constants so the `StartupGate.id` field is grep-stable across analytics
/// + debug logs even when the gate's predicate closure changes.
///
/// Per `ForgeNavigation.StartupGate`: gates evaluate in declaration order;
/// the first unsatisfied gate redirects to its destination. The MicrobeLab
/// flow has TWO ordered gates: parent handoff THEN kid onboarding. The
/// AppRootView Group does NOT currently use `StartupGate` directly (each
/// gate's condition closure would need to capture MainActor-isolated
/// stores), but exposing the IDs gives future ForgePhaseRouter consumers a
/// canonical gate-name set + lets analytics treat the same gate
/// consistently across surfaces.
public nonisolated enum MicrobeLabStartupGateID: String, Sendable, CaseIterable {
    case parentHandoffCompleted = "parent_handoff_completed"
    case kidOnboardingCompleted = "kid_onboarding_completed"
}
