import Foundation

/// Apple's Declared Age Range entitlement key. Read from `Bundle.main` via
/// the runtime probe rather than referenced as a symbol so the build stays
/// green on app targets that haven't yet provisioned the entitlement (per
/// `.claude/rules/age-assurance.md` § Declared Age Range API + the
/// entitlement-gated-framework guidance in `.claude/rules/warnings.md`).
public nonisolated enum AgeAssuranceEntitlement {
    public static let key = "com.apple.developer.declared-age-range"
}

/// Outcome of a verification attempt. The `notAttempted` case is what
/// downstream UI reads at launch — call `request*` methods to advance the
/// state.
public nonisolated enum AgeAssuranceResult: Sendable, Equatable {
    case notAttempted
    /// System-path verification completed — `adult == true` when the
    /// Declared Age Range API confirmed the user meets the gate.
    case systemVerified(adult: Bool)
    /// User declined sharing; the parental-control surface falls back to
    /// the math gate (`ParentalGateView`).
    case systemDeclined
    /// The system API isn't available on this device / entitlement chain
    /// (covered by `AgeAssuranceCapability.isDeclaredAgeRangeAvailable`).
    case systemUnavailable
}

/// Read-only capability probe. Use ahead of any UI affordance to decide
/// whether to surface the "Verify with Apple" entry point or fall straight
/// through to the math gate.
public nonisolated enum AgeAssuranceCapability {
    /// `true` when the host app declares the Declared Age Range
    /// entitlement in `Bundle.main`. The actual `request` call still
    /// needs to succeed at runtime — the entitlement is necessary but not
    /// sufficient (Apple may decline the share, the device may be
    /// configured without Family Sharing, etc.).
    ///
    /// Implementation note: this reads the `Info.plist`'s `Entitlements`
    /// dictionary if Xcode embedded it during the build. When the
    /// entitlement isn't provisioned, the key is absent and the probe
    /// returns `false`. This avoids the `SecTask*` `dlsym` dance used in
    /// the Network / KVS probes (those frameworks crash hard without the
    /// entitlement; the Declared Age Range request method throws and is
    /// caught by `ForgeSystemAgeGate`'s fallback path, so a softer probe
    /// suffices for surfacing the affordance).
    public static var isDeclaredAgeRangeAvailable: Bool {
        guard let entitlements = Bundle.main.object(forInfoDictionaryKey: "Entitlements") as? [String: Any] else {
            return false
        }
        return entitlements[AgeAssuranceEntitlement.key] != nil
    }
}

/// Scaffold service for the Declared Age Range pipeline. Holds the
/// most-recent verification result + the capability flag in a single
/// `@Observable` MainActor surface so SwiftUI can react without each
/// surface re-probing on every appearance.
///
/// **Status (2026-06-17)**: SwiftUI driver shipped at
/// `AppFeature.SystemAgeVerificationCard` — the actual `await
/// AgeRangeService.shared.requestAgeRange(ageGates:in:)` call lives in
/// the card's `verify()` method (UIKit anchor path via the key window's
/// root VC). This service remains the result-holder + capability probe;
/// `recordResult(_:)` is the seam the card calls when the system path
/// returns. The `requestSystemVerification(minimumAge:)` method below
/// stays as a no-op fallback used by non-UIKit contexts (tests, headless
/// scaffolds) — the real verification flow runs through the SwiftUI
/// card. Both paths are gated by `isCapable` (the soft entitlement probe);
/// without the `com.apple.developer.declared-age-range` entitlement the
/// system path uniformly returns `.systemUnavailable` and the math gate
/// in `ParentalGateView` remains the active surface.
///
/// Per `.claude/rules/age-assurance.md`: receiving "Under 13" creates
/// **COPPA actual knowledge** — all consent flows and record-keeping
/// requirements immediately apply. Do not advance to issuing the
/// `request` call until COPPA consent + retention are in place.
@MainActor
@Observable
public final class AgeAssuranceService {
    public private(set) var result: AgeAssuranceResult
    public let isCapable: Bool

    public init(initial: AgeAssuranceResult = .notAttempted) {
        self.result = initial
        self.isCapable = AgeAssuranceCapability.isDeclaredAgeRangeAvailable
    }

    /// Stage the result without making the system call. Used by tests +
    /// by the parental-control surface to record the math-gate outcome
    /// when the system path is unavailable.
    public func recordResult(_ next: AgeAssuranceResult) {
        result = next
        DebugLog.state("AgeAssuranceService — result \(String(describing: next))")
    }

    /// Request system verification via Apple's Declared Age Range API.
    ///
    /// **NOT YET ENABLED** — the implementation is a no-op until the
    /// entitlement is provisioned via the Xcode GUI (see
    /// `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § Declared Age Range API
    /// entitlement). When `isCapable == false` this returns immediately
    /// with `.systemUnavailable` so callers handle the disabled case
    /// uniformly.
    ///
    /// The actual `await requestAgeRange(...)` call belongs in
    /// `ForgeAccessibility.ForgeSystemAgeGate` — we keep this method as
    /// a service-side seam so the parent-handoff flow can stage the
    /// request the same way regardless of which UI surface ultimately
    /// hosts the gate.
    public func requestSystemVerification(minimumAge: Int = 13) async -> AgeAssuranceResult {
        guard isCapable else {
            DebugLog.permission("AgeAssuranceService — system path unavailable; falling back to math gate")
            recordResult(.systemUnavailable)
            return .systemUnavailable
        }
        // Scaffold: when the entitlement is provisioned, replace this
        // stub with a call into ForgeSystemAgeGate's underlying API. The
        // shape below mirrors the eventual production path so the
        // call-site doesn't change at unblock time.
        DebugLog.permission("AgeAssuranceService — scaffold path; entitlement provisioned but request handler is a stub (minimumAge=\(minimumAge))")
        recordResult(.notAttempted)
        return .notAttempted
    }
}
