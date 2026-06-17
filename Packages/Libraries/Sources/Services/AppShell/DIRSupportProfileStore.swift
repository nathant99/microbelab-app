import Foundation
import Observation
import ForgeDevelopmental

/// On-device UserDefaults-backed persistence of the kid's
/// `UserFEDCProfile` — the canonical DIR / FEDC affect-aware profile shipped
/// by ForgeKit 0.86's `ForgeDevelopmental` module per
/// `.claude/rules/forgekit.md` § Module Catalog.
///
/// **Scope**: this PR wires the ForgeDevelopmental module + ships the
/// MicrobeLab-side persistence seam. Consumer surfaces (the engagement-
/// foundation overlays — `SessionNudgeOverlay` / `WelcomeBackOverlay` /
/// `StreakRescueOverlay`) opt into DIR-aware copy by reading
/// `currentLevel` / `estimatedBand` when those views land their next
/// trauma-informed refresh. The scaffold is intentionally thin so future
/// rounds can deepen the integration surface-by-surface without
/// re-touching Package.swift or the persistence seam.
///
/// **Why ForgeDevelopmental in MicrobeLab**: per `.claude/rules/forgekit.md`
/// the module ships DIR/FEDC scaffolding (16 levels, capacity-based support,
/// affect-aware adaptive features) that aligns naturally with MicrobeLab's
/// trauma-informed posture (microbiology-as-cooperation register, never
/// warfare; session-target / streak-rescue / welcome-back surfaces). Wiring
/// early means future engagement work can opt into DIR-aware nudges + cue
/// pacing without re-arguing the integration.
///
/// **COPPA + retention posture** (per `.claude/rules/age-assurance.md`
/// § Portfolio Status + 2026 FTC COPPA Rule § Data retention limits):
///
/// - Storage is **on-device only**. No remote sync, no third-party SDK.
/// - Storage is **ring-buffered at 100 demonstrations** so the profile
///   doesn't grow unbounded; FIFO eviction drops the oldest when the cap
///   is hit. 100 is a deliberate choice that lets `estimatedLevel()` see
///   enough density to surface a stable level estimate across multiple
///   weeks of play, while staying small enough that UserDefaults
///   persistence stays under a few hundred bytes per kid.
/// - `clear()` wipes the profile (used by parental controls when a
///   grown-up wants to reset the kid's DIR scaffolding).
@MainActor
@Observable
public final class DIRSupportProfileStore {
    public private(set) var profile: UserFEDCProfile

    /// Capacity ceiling for the demonstration ring buffer. 100 is a
    /// deliberate choice — large enough that `UserFEDCProfile.estimatedLevel()`
    /// sees stable density across multiple weeks of play, small enough that
    /// the JSON-encoded persistence stays under a few hundred bytes.
    public static let capacity = 100

    /// Bundle identifier surfaced into every demonstration record. Required
    /// by `FEDCDemonstrationRecord.appIdentifier` so future
    /// cross-portfolio FEDC aggregation can attribute the demonstration to
    /// MicrobeLab vs sibling apps.
    public static let appIdentifier = "com.microbelab.app"

    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        defaults: UserDefaults = .standard,
        key: String = "microbelab.engagement.dirProfile"
    ) {
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(UserFEDCProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserFEDCProfile()
        }
    }

    /// Append a fresh demonstration record. FIFO-evicts the oldest if at
    /// capacity so the profile doesn't grow unbounded.
    ///
    /// - Parameters:
    ///   - level: The FEDC capacity demonstrated (per
    ///     `ForgeDevelopmental.FEDCLevel`'s 16-level ladder).
    ///   - context: Surface that produced the demonstration. Choose:
    ///     `.task` for kit-completion / quiz-correct paths;
    ///     `.reflection` for the ForgeKit 0.99.0 reflection-prompt
    ///     `.text`-modality entries; `.coregulation` for parent-handoff +
    ///     parental-gate-aware flows; `.conversation` for the Vee mentor
    ///     surface.
    ///   - confidence: How strong the signal is. `.speculative` for
    ///     edge-of-tier / first-attempt evidence; `.clear` for sustained
    ///     evidence; `.robust` for multiple consistent demonstrations.
    public func recordDemonstration(
        level: FEDCLevel,
        context: FEDCDemonstrationRecord.Context,
        confidence: FEDCDemonstrationRecord.Confidence,
        demonstratedAt: Date = .now
    ) {
        let record = FEDCDemonstrationRecord(
            fedcLevel: level,
            demonstratedAt: demonstratedAt,
            context: context,
            confidence: confidence,
            appIdentifier: Self.appIdentifier
        )
        var demos = profile.demonstrations + [record]
        if demos.count > Self.capacity {
            demos.removeFirst(demos.count - Self.capacity)
        }
        profile = UserFEDCProfile(demonstrations: demos)
        flush()
    }

    /// Convenience accessor — the kid's currently-estimated FEDC level
    /// derived from the profile's demonstration density + confidence. Nil
    /// when no demonstrations have been recorded yet (fresh install).
    public var currentLevel: FEDCLevel? {
        profile.estimatedLevel()
    }

    /// Convenience accessor — the FEDC band the kid's current level belongs
    /// to. Nil when no demonstrations have been recorded yet.
    public var estimatedBand: FEDCLevelBand? {
        guard let level = currentLevel else { return nil }
        return profile.currentBand(for: level)
    }

    /// Whether the profile has at least one demonstration. Useful for
    /// gating "DIR-aware" overlay copy on consumer surfaces.
    public var hasAnyDemonstration: Bool {
        !profile.demonstrations.isEmpty
    }

    /// Wipe the profile. Used by parental controls when the grown-up wants
    /// to reset the DIR scaffolding (e.g., new kid using the same device).
    public func clear() {
        profile = UserFEDCProfile()
        defaults.removeObject(forKey: key)
    }

    // MARK: - Persistence

    private func flush() {
        guard let data = try? encoder.encode(profile) else { return }
        defaults.set(data, forKey: key)
    }
}
