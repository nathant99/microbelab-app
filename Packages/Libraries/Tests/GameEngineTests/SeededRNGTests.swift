import Foundation
import Testing
@testable import GameEngine

@Suite("SeededRNG")
nonisolated struct SeededRNGTests {
    @Test func sameSeedProducesSameSequence() {
        var a = SeededRNG(seed: 42)
        var b = SeededRNG(seed: 42)
        for _ in 0..<32 {
            #expect(a.next() == b.next())
        }
    }

    @Test func differentSeedsDiverge() {
        var a = SeededRNG(seed: 1)
        var b = SeededRNG(seed: 2)
        // It's almost impossible for splitmix64 to align on a 16-draw window
        // from neighbouring seeds; the post-mix step guarantees decorrelation.
        var divergedSomewhere = false
        for _ in 0..<16 where a.next() != b.next() {
            divergedSomewhere = true
        }
        #expect(divergedSomewhere)
    }

    @Test func nextUnitStaysInUnitInterval() {
        var rng = SeededRNG(seed: 7)
        for _ in 0..<1_000 {
            let value = rng.nextUnit()
            #expect(value >= 0.0)
            #expect(value < 1.0)
        }
    }

    @Test func nextJitterStaysWithinMagnitudeBand() {
        var rng = SeededRNG(seed: 11)
        let magnitude = 0.25
        for _ in 0..<1_000 {
            let jitter = rng.nextJitter(magnitude: magnitude)
            #expect(jitter >= -magnitude)
            #expect(jitter < magnitude)
        }
    }

    @Test func conformsToRandomNumberGeneratorProtocol() {
        var rng = SeededRNG(seed: 5)
        // Use as the RandomNumberGenerator for a Standard-Library API.
        let drawn = Int.random(in: 1...10, using: &rng)
        #expect((1...10).contains(drawn))
    }
}
