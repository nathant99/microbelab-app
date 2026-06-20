import Foundation
import Testing
import ForgeModels
@testable import Services

@Suite("EmotionSnapshotDerivation")
struct EmotionSnapshotDerivationTests {
    @Test func calmSeverityReturnsNilSnapshot() {
        let snapshot = EmotionSnapshotDerivation.from(despairSeverity: .calm)
        #expect(snapshot == nil, "calm severity must NOT imply a positive snapshot; v1 fallback path stays in force")
    }

    @Test func elevatedDistressReturnsModerateBandSnapshot() throws {
        let captured = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = try #require(
            EmotionSnapshotDerivation.from(despairSeverity: .elevatedDistress, capturedAt: captured)
        )
        #expect(snapshot.source == .derivedFromTask, "MicrobeLab never reads biometric sources")
        #expect(snapshot.capturedAt == captured, "captured stamp must round-trip for determinism in tests")
        // Moderate distress band — kicks in pacing guidance without crossing the
        // SAMHSA acute-presence trifecta.
        #expect(snapshot.distressScore >= 0.4 && snapshot.distressScore < 0.7,
                "moderate distress band: 0.4..<0.7 (per rc.3 prompt registry breakpoints)")
        #expect(snapshot.arousalScore >= 0.4 && snapshot.arousalScore < 0.75,
                "moderate arousal band: 0.4..<0.75 (avoids the over-stimulated cue)")
        #expect(snapshot.valenceScore == nil,
                "valence stays unmeasured at moderate severity — rc.3 treats nil as unmeasured NOT neutral")
    }

    @Test func elevatedCrisisReturnsAcuteTrifectaSnapshot() throws {
        let snapshot = try #require(EmotionSnapshotDerivation.from(despairSeverity: .elevatedCrisis))
        // The rc.3 changelog defines the SAMHSA acute-presence trifecta as
        // distress ≥ 0.7 AND arousal ≥ 0.7 AND valence ≤ -0.5. The crisis
        // derivation MUST satisfy all three so the prompt registry surfaces
        // the SAMHSA-presence cue, not just the moderate pacing guidance.
        #expect(snapshot.distressScore >= 0.7, "crisis distress must satisfy the rc.3 acute trifecta")
        #expect(snapshot.arousalScore >= 0.7, "crisis arousal must satisfy the rc.3 acute trifecta")
        let valence = try #require(snapshot.valenceScore)
        #expect(valence <= -0.5, "crisis valence must satisfy the rc.3 acute trifecta (≤ -0.5)")
        #expect(snapshot.source == .derivedFromTask)
    }

    @Test func defaultCapturedAtClockHopsForward() throws {
        // The Date() default param means two calls a moment apart should yield
        // monotonically-increasing capturedAt — load-bearing for the rc.3
        // continuous-band guidance which dedups by stamp.
        let first = try #require(EmotionSnapshotDerivation.from(despairSeverity: .elevatedDistress))
        Thread.sleep(forTimeInterval: 0.01)
        let second = try #require(EmotionSnapshotDerivation.from(despairSeverity: .elevatedDistress))
        #expect(second.capturedAt >= first.capturedAt)
    }

    @Test(arguments: [DespairSignalDetector.Severity.elevatedDistress, .elevatedCrisis])
    func nonCalmSeveritiesAlwaysReturnSnapshot(severity: DespairSignalDetector.Severity) {
        #expect(EmotionSnapshotDerivation.from(despairSeverity: severity) != nil,
                "non-calm severities must never silently degrade to v1 fallback")
    }
}
