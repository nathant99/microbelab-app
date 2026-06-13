import Testing
@testable import Services
import Models

@Suite("MasteryMomentDetector")
struct MasteryMomentDetectorTests {

    // MARK: - Ecology mastery

    @Test("Ecology mastery fires at threshold with fiber feeding")
    func ecologyMasteryFiresAtThreshold() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordEcologyTick(
            stableTickRun: MasteryMomentDetector.ecologyMasteryStableTickThreshold,
            feedingMode: .fiber
        )
        let unwrapped = try! #require(moment)
        #expect(unwrapped.kind == .ecologyMaster)
        #expect(detector.acknowledged.contains(.ecologyMaster))
    }

    @Test("Ecology mastery does not fire below threshold")
    func ecologyMasteryBelowThreshold() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordEcologyTick(
            stableTickRun: MasteryMomentDetector.ecologyMasteryStableTickThreshold - 1,
            feedingMode: .fiber
        )
        #expect(moment == nil)
        #expect(detector.acknowledged.isEmpty)
    }

    @Test("Ecology mastery requires fiber feeding mode")
    func ecologyMasteryRequiresFiber() {
        for mode in [FeedingMode.sugar, .balanced, .none] {
            var detector = MasteryMomentDetector()
            let moment = detector.recordEcologyTick(
                stableTickRun: MasteryMomentDetector.ecologyMasteryStableTickThreshold + 5,
                feedingMode: mode
            )
            #expect(moment == nil, "Mode \(mode) should not trigger ecology mastery")
        }
    }

    @Test("Ecology mastery fires exactly once per session")
    func ecologyMasteryIsOneShot() {
        var detector = MasteryMomentDetector()
        let first = detector.recordEcologyTick(stableTickRun: 15, feedingMode: .fiber)
        let second = detector.recordEcologyTick(stableTickRun: 20, feedingMode: .fiber)
        #expect(first != nil)
        #expect(second == nil)
    }

    // MARK: - Defense mastery

    @Test("Defense mastery fires on perfect 5-wave run")
    func defenseMasteryFiresOnPerfectRun() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordDefenseRunComplete(wavesCleared: 5, pathogensRemaining: 0)
        let unwrapped = try! #require(moment)
        #expect(unwrapped.kind == .defenseMaster)
    }

    @Test("Defense mastery does not fire on incomplete run")
    func defenseMasteryIncompleteRun() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordDefenseRunComplete(wavesCleared: 4, pathogensRemaining: 0)
        #expect(moment == nil)
    }

    @Test("Defense mastery does not fire when pathogens remain")
    func defenseMasteryWithPathogensRemaining() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordDefenseRunComplete(wavesCleared: 5, pathogensRemaining: 1)
        #expect(moment == nil)
    }

    @Test("Defense mastery fires exactly once per session")
    func defenseMasteryIsOneShot() {
        var detector = MasteryMomentDetector()
        let first = detector.recordDefenseRunComplete(wavesCleared: 5, pathogensRemaining: 0)
        let second = detector.recordDefenseRunComplete(wavesCleared: 5, pathogensRemaining: 0)
        #expect(first != nil)
        #expect(second == nil)
    }

    // MARK: - Codex mastery

    @Test("Codex mastery fires when every microbe discovered")
    func codexMasteryFires() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordCodexDiscovery(totalDiscovered: 12, totalAvailable: 12)
        let unwrapped = try! #require(moment)
        #expect(unwrapped.kind == .codexMaster)
    }

    @Test("Codex mastery does not fire below total")
    func codexMasteryBelowTotal() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordCodexDiscovery(totalDiscovered: 11, totalAvailable: 12)
        #expect(moment == nil)
    }

    @Test("Codex mastery defensive: zero-catalog is a no-op")
    func codexMasteryDefensiveZeroCatalog() {
        var detector = MasteryMomentDetector()
        let moment = detector.recordCodexDiscovery(totalDiscovered: 0, totalAvailable: 0)
        #expect(moment == nil)
    }

    // MARK: - Trauma-informed copy invariants

    @Test("All mastery moment headlines + sublines avoid shame / comparison register")
    func traumaInformedCopyInvariants() {
        // Trigger one moment per kind and walk the copy stoplist.
        let stoplist = [
            "finally", "at last", "you almost", "you nearly", "should have",
            "must have", "failed", "behind", "compared to", "better than"
        ]
        var detector = MasteryMomentDetector()
        let ecology = detector.recordEcologyTick(stableTickRun: 15, feedingMode: .fiber)!
        var detector2 = MasteryMomentDetector()
        let defense = detector2.recordDefenseRunComplete(wavesCleared: 5, pathogensRemaining: 0)!
        var detector3 = MasteryMomentDetector()
        let codex = detector3.recordCodexDiscovery(totalDiscovered: 12, totalAvailable: 12)!
        for moment in [ecology, defense, codex] {
            let combined = "\(moment.headline) \(moment.subline)".lowercased()
            for forbidden in stoplist {
                #expect(
                    !combined.contains(forbidden),
                    "Forbidden register token '\(forbidden)' in \(moment.kind.rawValue) copy: \(combined)"
                )
            }
        }
    }

    // MARK: - acknowledge() idempotency

    @Test("acknowledge is idempotent + suppresses future fires")
    func acknowledgeIsIdempotent() {
        var detector = MasteryMomentDetector()
        detector.acknowledge(.ecologyMaster)
        detector.acknowledge(.ecologyMaster) // safe double-call
        #expect(detector.acknowledged == [.ecologyMaster])
        let moment = detector.recordEcologyTick(stableTickRun: 100, feedingMode: .fiber)
        #expect(moment == nil)
    }
}
