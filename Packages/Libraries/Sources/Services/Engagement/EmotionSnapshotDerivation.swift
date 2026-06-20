import Foundation
import ForgeModels

/// Pure-value helper that derives a `ForgeModels.EmotionSnapshot` from
/// MicrobeLab's on-device despair-signal screening (`DespairSignalDetector`).
/// Feeds the per-utterance affect-attunement pipeline shipped by ForgeKit
/// 1.0.0-rc.3 (`CastDialogContext.emotionSnapshot`), so cast voicing can
/// adapt sentence-length + pacing + SAMHSA-presence cue from the kid's
/// recent reflection signals.
///
/// **Why this is the right signal source**:
/// `EmotionSnapshot.Source.derivedFromTask` covers "inferred from in-app
/// behavior (response latency, error clustering, etc.)". The reflection
/// surface already screens free-text entries through the conservative
/// SAMHSA-derived phrase stoplist (PR #167) and emits a categorical
/// severity. Mapping that severity into the continuous distress/arousal
/// bands is the appropriate non-biometric `derivedFromTask` derivation —
/// we never read camera / microphone / biometric input per the COPPA-2025
/// constraint on `EmotionSnapshot.Source`.
///
/// **Trauma-informed posture** (load-bearing):
/// - `.calm` returns `nil`. The v1 fallback path inside CastDialog still
///   wins — never imply a positive valence from absence-of-distress.
/// - `.elevatedDistress` returns a moderate-distress snapshot with
///   `valenceScore = nil` (unmeasured, NOT neutral per the rc.3 changelog).
///   Pacing guidance kicks in; explicit affect-naming is suppressed for
///   `.greeting` / `.affirmation` triggers per the prompt registry.
/// - `.elevatedCrisis` returns the acute-distress trifecta the rc.3
///   prompt registry treats as a SAMHSA-presence cue: distress ≥ 0.7
///   AND arousal ≥ 0.7 AND valence ≤ -0.5.
///
/// The derivation NEVER bypasses the despair-signal crisis-resource
/// surface (`DespairSignalSurface.presentation(for:)`). The two paths run
/// in parallel: the crisis-resource surface stays the primary
/// kid-facing safety affordance; the affect-attuned voicing path adapts
/// the cast voice register on the SAME signal.
public nonisolated enum EmotionSnapshotDerivation {
    /// Derive a snapshot from a despair-signal severity.
    ///
    /// - Parameters:
    ///   - despairSeverity: The categorical severity returned by
    ///     `DespairSignalDetector.detect(in:)`.
    ///   - capturedAt: Wall-clock capture stamp. Defaults to `.now` so
    ///     callers don't need to plumb a clock through the engagement
    ///     surfaces; pass a fixed `Date` from tests for determinism.
    /// - Returns: An `EmotionSnapshot` when the severity warrants
    ///   continuous-band guidance; `nil` for `.calm` so the legacy
    ///   `emotionContext` enum keeps the v1 path inside CastDialog.
    public nonisolated static func from(
        despairSeverity: DespairSignalDetector.Severity,
        capturedAt: Date = .now
    ) -> EmotionSnapshot? {
        switch despairSeverity {
        case .calm:
            return nil
        case .elevatedDistress:
            return EmotionSnapshot(
                distressScore: 0.55,
                arousalScore: 0.5,
                valenceScore: nil,
                capturedAt: capturedAt,
                source: .derivedFromTask
            )
        case .elevatedCrisis:
            return EmotionSnapshot(
                distressScore: 0.85,
                arousalScore: 0.75,
                valenceScore: -0.6,
                capturedAt: capturedAt,
                source: .derivedFromTask
            )
        }
    }
}
