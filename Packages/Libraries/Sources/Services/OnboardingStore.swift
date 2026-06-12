import Foundation

/// UserDefaults-backed persistence of the first-time-experience completion
/// state. Lives in `Services` so non-UI callers (tests, ParentalGate, future
/// debug menu) can read or reset it.
///
/// Per `.claude/rules/age-assurance.md` § 2026 FTC COPPA — we do NOT persist
/// any PII through this store. The flag is a binary boolean.
@MainActor
public final class OnboardingStore {
    private let defaults: UserDefaults
    private let key: String
    public private(set) var hasCompletedOnboarding: Bool

    public init(defaults: UserDefaults = .standard, key: String = "MicrobeLab.OnboardingCompleted") {
        self.defaults = defaults
        self.key = key
        self.hasCompletedOnboarding = defaults.bool(forKey: key)
    }

    public func markCompleted() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: key)
        DebugLog.state("OnboardingStore — marked completed")
    }

    /// Reset for debug menus + the test surface. App code should not call this
    /// in normal flow.
    public func reset() {
        hasCompletedOnboarding = false
        defaults.set(false, forKey: key)
        DebugLog.state("OnboardingStore — reset")
    }
}
