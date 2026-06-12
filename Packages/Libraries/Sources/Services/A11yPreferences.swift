import Foundation

/// Resolved accessibility preferences combining system-level Reduce Motion
/// + Reduce Transparency with the parent-gated `AppSettings` force
/// overrides. Pure value type — testable without UIKit / SwiftUI.
///
/// Semantics: OR-combine. The force toggles can REDUCE more than the
/// system asks; they cannot un-reduce when the system has asked. This
/// matches Apple's HIG guidance that app-level settings layer on top of
/// system accessibility, never below.
///
/// Per `Docs/FEATURE_PLAN.md` § Accessibility & Trauma-Informed Polish:
/// > Reduce-Motion variants for celebration + tier-transition animations
/// > Reduce-Transparency variants for any glass UI (per portfolio Liquid Glass policy)
///
/// Consumers branch on `reduceMotion` (drop animation duration / scale
/// transitions / morph effects) and `reduceTransparency` (swap
/// `.thinMaterial` / `.glassEffect` for solid fills).
public nonisolated struct A11yPreferences: Sendable, Equatable {
    public let reduceMotion: Bool
    public let reduceTransparency: Bool

    public init(reduceMotion: Bool, reduceTransparency: Bool) {
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
    }

    /// Default preferences — no reduction. Used as a fallback / preview
    /// stand-in.
    public static let none = A11yPreferences(
        reduceMotion: false,
        reduceTransparency: false
    )

    /// OR-combine the system accessibility env values with the app's
    /// `forceReduceMotion` / `forceReduceTransparency` toggles.
    public static func resolved(
        systemReduceMotion: Bool,
        systemReduceTransparency: Bool,
        settings: AppSettings
    ) -> A11yPreferences {
        A11yPreferences(
            reduceMotion: systemReduceMotion || settings.forceReduceMotion,
            reduceTransparency: systemReduceTransparency || settings.forceReduceTransparency
        )
    }
}
