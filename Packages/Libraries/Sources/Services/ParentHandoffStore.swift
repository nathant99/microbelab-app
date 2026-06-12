import Foundation

/// UserDefaults-backed persistence of the 30-second parent handoff completion
/// flag. Per `Docs/FEATURE_PLAN.md` § Onboarding & Child Safety: a grown-up
/// confirms a small set of preferences ONCE before the kid sees the 5-step
/// onboarding flow.
///
/// We intentionally do NOT persist parent PII — just a binary "has completed"
/// flag. Actual preferences (disease story gate, daily cap) flow into
/// `AppSettingsStore` so the Settings tab is the single source of truth.
///
/// Per `.claude/rules/age-assurance.md` § 2026 FTC COPPA, the parent handoff
/// is the conventional surface for parental-consent affirmation. Apple
/// Declared Age Range API integration (iOS 26.2+) ships as its own follow-up
/// per the FEATURE_PLAN item; this store only owns the handoff-completion
/// signal.
@MainActor
public final class ParentHandoffStore {
    private let defaults: UserDefaults
    private let key: String
    public private(set) var hasCompletedHandoff: Bool

    public init(defaults: UserDefaults = .standard, key: String = "MicrobeLab.ParentHandoffCompleted") {
        self.defaults = defaults
        self.key = key
        self.hasCompletedHandoff = defaults.bool(forKey: key)
    }

    public func markCompleted() {
        hasCompletedHandoff = true
        defaults.set(true, forKey: key)
        DebugLog.state("ParentHandoffStore — marked completed")
    }

    /// Reset for debug menus + the test surface. App code should not call this
    /// in normal flow.
    public func reset() {
        hasCompletedHandoff = false
        defaults.set(false, forKey: key)
        DebugLog.state("ParentHandoffStore — reset")
    }
}
