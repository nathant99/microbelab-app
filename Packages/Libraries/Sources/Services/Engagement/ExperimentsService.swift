import Foundation
import ForgeExperiments

/// On-device A/B experiment surface for MicrobeLab. Wraps
/// `ForgeExperiments.ExperimentAssigner` — a `SHA256(seed|experimentID)`-bucketed
/// deterministic assignment that needs no network call, no third-party SDK, and
/// no per-user identifier outside the device. The seed should be a stable
/// per-installation token (e.g., `StudentProfile.id.uuidString` once the player
/// profile exists, or `UUID().uuidString` written to UserDefaults on first
/// launch). Same seed + same experimentID = same variant — the bucketing is
/// stable across launches without persisting the assignment.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Feature flags, MicrobeLab needs on-device,
/// COPPA-safe A/B testing for Phase 2 progressive-disclosure cadence + Phase 4
/// seasonal content gating. This service is the canonical entry point.
///
/// Two pilot experiments ship at construction time:
///
/// - `progressiveDisclosureV2` — toggles a staged-unlock cadence variant for
///   the adaptive-immunity mode-card progression. Two variants: `control`
///   (single-gate per kit, the canonical pre-v2 path) and `staged` (per-load
///   intermediate cues that surface the next mode-card 2 ticks earlier). Used
///   by `AdaptiveImmunityUnlock` to A/B the unlock cadence.
/// - `seasonalContentGate` — toggles whether the Phase 4 seasonal content
///   pack (Halloween / WorldMicrobiomeDay) is surfaced at all. Two variants:
///   `control` (no seasonal pack) and `enabled` (seasonal pack surfaces). Used
///   by `MicrobeCatalogService` extension when Phase 4 ships.
///
/// Both pilots default to `control` until the seasonal release ships; the
/// service exists today to land the wiring so Phase 2+ feature work can flip
/// the variant assignment without re-touching the seam.
@MainActor
@Observable
public final class ExperimentsService {

    public static let progressiveDisclosureV2ID = "progressive_disclosure_v2"
    public static let seasonalContentGateID = "seasonal_content_gate"
    /// `cast_voicing` — gates the DN-S AI-mentor voicing surface (per
    /// `Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md`). When the
    /// `enabled` variant flips on, `VeeMentor` dispatches utterances through
    /// the per-cast `CastDialog` actor instead of the default Socratic
    /// surface. Default 100% control until the focused DN-S voicing round
    /// flips the weight + ships an in-app debug toggle for TestFlight.
    public static let castVoicingID = "cast_voicing"

    private let experiments: [String: ExperimentDefinition]
    private let seed: String

    public init(seed: String, experiments: [ExperimentDefinition] = ExperimentsService.defaultExperiments()) {
        self.seed = seed
        self.experiments = Dictionary(uniqueKeysWithValues: experiments.map { ($0.id, $0) })
    }

    /// Convenience initializer with a UUID seed (use in tests or first-launch
    /// flows where the per-installation seed hasn't been written to
    /// UserDefaults yet).
    public convenience init() {
        self.init(seed: UUID().uuidString)
    }

    /// Returns the assigned variant for `experimentID`. Returns `nil` if the
    /// experiment isn't registered.
    public func assignedVariant(for experimentID: String) -> Variant? {
        guard let definition = experiments[experimentID] else { return nil }
        return ExperimentAssigner.assignVariant(
            experimentID: experimentID,
            variants: definition.variants,
            seed: seed
        )
    }

    /// Boolean feature-flag convenience. Returns `true` when the assigned
    /// variant's `id` matches `enabledVariantID`. Defaults to `false` when the
    /// experiment isn't registered.
    public func isEnabled(_ experimentID: String, enabledVariantID: String = "enabled") -> Bool {
        assignedVariant(for: experimentID)?.id == enabledVariantID
    }

    /// Reads a typed parameter from the assigned variant. Returns
    /// `defaultValue` when the experiment isn't registered or the parameter
    /// key isn't present.
    public func intParameter(_ key: String, in experimentID: String, default defaultValue: Int) -> Int {
        guard case .int(let value) = assignedVariant(for: experimentID)?.parameters[key] else {
            return defaultValue
        }
        return value
    }

    public func doubleParameter(_ key: String, in experimentID: String, default defaultValue: Double) -> Double {
        guard case .double(let value) = assignedVariant(for: experimentID)?.parameters[key] else {
            return defaultValue
        }
        return value
    }

    public func boolParameter(_ key: String, in experimentID: String, default defaultValue: Bool) -> Bool {
        guard case .bool(let value) = assignedVariant(for: experimentID)?.parameters[key] else {
            return defaultValue
        }
        return value
    }

    public func stringParameter(_ key: String, in experimentID: String, default defaultValue: String) -> String {
        guard case .string(let value) = assignedVariant(for: experimentID)?.parameters[key] else {
            return defaultValue
        }
        return value
    }

    /// The two default pilot experiments ship at construction time. Both
    /// default to `control` until a focused Phase-2 / Phase-4 round flips the
    /// variant weight.
    public static func defaultExperiments() -> [ExperimentDefinition] {
        let now = Date()
        let later = now.addingTimeInterval(60 * 60 * 24 * 365)
        return [
            ExperimentDefinition(
                id: progressiveDisclosureV2ID,
                name: "Progressive Disclosure v2",
                description: "Staged-unlock cadence for the adaptive-immunity mode-card progression. The 'staged' variant surfaces the next mode-card 2 ticks earlier than the canonical single-gate path.",
                variants: [
                    Variant(id: "control", name: "Single-gate (canonical)", weight: 100),
                    Variant(id: "staged", name: "Staged cadence", weight: 0, parameters: [
                        "earlyUnlockTicks": .int(2),
                    ]),
                ],
                startDate: now,
                endDate: later,
                minimumSessions: 30,
                primaryMetric: .retention(.d7)
            ),
            ExperimentDefinition(
                id: seasonalContentGateID,
                name: "Seasonal Content Gate",
                description: "Toggles whether the Phase 4 seasonal content pack (Halloween / WorldMicrobiomeDay etc.) is surfaced. 'enabled' surfaces the seasonal microbe variants + skin map; 'control' keeps the canonical year-round catalog.",
                variants: [
                    Variant(id: "control", name: "Year-round catalog (canonical)", weight: 100),
                    Variant(id: "enabled", name: "Seasonal pack enabled", weight: 0),
                ],
                startDate: now,
                endDate: later,
                minimumSessions: 30,
                primaryMetric: .sessionsPerWeek
            ),
            ExperimentDefinition(
                id: castVoicingID,
                name: "DN-S AI-Mentor Voicing",
                description: "Toggles whether VeeMentor dispatches utterances through the per-cast `CastDialog` actor (using the 6 `CastVoiceProfile` instances authored from the chapter MDs) instead of the default Socratic surface. Default 100% control; the focused DN-S voicing round flips weight + ships an in-app debug toggle for TestFlight per `Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` § Implementation step 4.",
                variants: [
                    Variant(id: "control", name: "Default Socratic mentor (canonical)", weight: 100),
                    Variant(id: "enabled", name: "Cast voicing enabled", weight: 0),
                ],
                startDate: now,
                endDate: later,
                minimumSessions: 30,
                primaryMetric: .sessionsPerWeek
            ),
        ]
    }
}
