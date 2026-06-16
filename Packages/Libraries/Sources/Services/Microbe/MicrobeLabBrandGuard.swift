import Foundation
import ForgeLocalization

/// Brand-protection registry for MicrobeLab's app name + DN cast names.
///
/// Wraps `ForgeLocalization.ForgeBrandGuard` with the MicrobeLab-specific
/// protected term set. Use `verbatim(_:)` for any string that must NOT be
/// translated when the `.xcstrings` catalog ships:
///
/// 1. **App name** — "MicrobeLab" must always render in English per the
///    brand-architecture rules; localizers may translate the tagline but
///    never the app name itself
/// 2. **Microbe character names** — Lacto / Yeast / Photo / Net / Spore /
///    Guard / Bifido / Akker / Strep / Coli / Rhino / Deino / Sebu / Demi
///    / Halo / Pylo / Sweet / Nodu / Therm / Loam — these are kid-friendly
///    nicknames the DN methodology binds to specific curricular primitives
///    (per `.claude/rules/distributed-narrative.md` § What the cast IS).
///    Translating them would break the cast IS the curriculum mapping
/// 3. **Cast mentor names** — Vee (the Socratic mentor) + Cilia (the hub
///    mentor persona per PR #74). Same DN-rationale as character names
/// 4. **Curriculum / technical terms** — NGSS standard codes (e.g.
///    "NGSS MS-LS1-1") + the term "DN" (distributed narrative) when used
///    as a methodology marker
///
/// **Per `.claude/rules/localization.md`**: `Text(verbatim: "MicrobeLab")`
/// in SwiftUI prevents accidental translation; `String(localized: ...)` for
/// non-Text usage is the canonical pattern. This service exposes the
/// canonical protected-term set so any view + service surfacing brand
/// strings can share the same guard.
///
/// **Scope discipline**: this PR ships the registry ONLY. The `.xcstrings`
/// migration is downstream — when it lands, view consumers wire
/// `MicrobeLabBrandGuard.shared.verbatim(...)` at brand-name string sites.
/// Current code uses `Text(verbatim:)` directly per `localization.md`;
/// this scaffold prepares the centralized list so the migration is a
/// search-and-replace rather than a per-string audit.
public nonisolated struct MicrobeLabBrandGuard: Sendable {

    /// Shared instance with the canonical MicrobeLab protected-term set.
    /// Stateless; instance reuse is purely a convenience.
    public static let shared = MicrobeLabBrandGuard()

    /// Canonical protected-term set. Stable; the cast names list grows when
    /// new microbes ship — keep this in sync with `Services/Resources/microbes.json`.
    public static let canonicalProtectedTerms: [String] = [
        // App name
        "MicrobeLab",
        // Mentor names
        "Vee", "Cilia",
        // Phase 1 + Phase 2 microbe cast (20)
        "Lacto", "Yeast", "Photo", "Net", "Spore", "Guard",
        "Bifido", "Akker", "Strep", "Coli", "Rhino", "Deino",
        "Sebu", "Demi", "Halo", "Pylo", "Sweet", "Nodu", "Therm", "Loam",
        // Methodology markers
        "DN", "DN-S", "ForgeKit",
        // NGSS standards (kid-facing chips that must stay verbatim)
        "NGSS", "MS-LS1-1", "MS-LS1-3", "MS-LS2-1", "MS-LS4-2"
    ]

    private let guardImpl: ForgeBrandGuard

    public init() {
        self.guardImpl = ForgeBrandGuard(additionalTerms: Self.canonicalProtectedTerms)
    }

    /// True iff the term is in the canonical protected set OR the ForgeKit
    /// baseline ("Forge" / "ForgeKit" / "ForgePass").
    public func isProtected(_ text: String) -> Bool {
        guardImpl.isProtected(text)
    }

    /// Wraps a brand name for safe display. Returns the string unchanged;
    /// exists as a semantic marker that the caller has intentionally
    /// chosen not to localize. Pair with SwiftUI `Text(verbatim:)` at the
    /// view layer.
    public func verbatim(_ text: String) -> String {
        guardImpl.verbatim(text)
    }

    /// All currently registered protected terms. Test fixture entry point.
    public var terms: Set<String> { guardImpl.terms }
}
