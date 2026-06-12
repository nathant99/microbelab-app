import Foundation

/// Deterministic, seedable pseudo-random number generator for the microbiome
/// simulator + immune minigame.
///
/// Implements `splitmix64` per Vigna 2014 — a fast, statistically-strong PRNG
/// with a 64-bit state. Mutating `next()` advances the state in a way that's
/// fully reproducible from the seed, so tests can snapshot a 100-tick run with
/// a fixed seed and re-run it byte-for-byte.
///
/// Conforms to `RandomNumberGenerator` so it drops into any Standard-Library
/// API expecting one (`Int.random(in:using:)`, `Array.shuffled(using:)`, etc.).
///
/// Pure value type, `nonisolated` per `.claude/rules/concurrency.md` — safe to
/// pass across actor boundaries.
public nonisolated struct SeededRNG: RandomNumberGenerator, Sendable, Equatable {
    public private(set) var state: UInt64

    public init(seed: UInt64) {
        // Mix the seed once so adjacent seeds (0, 1, 2, …) don't produce
        // visibly correlated first draws.
        var s = seed &+ 0x9E37_79B9_7F4A_7C15
        s = (s ^ (s &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        s = (s ^ (s &>> 27)) &* 0x94D0_49BB_1331_11EB
        s ^= (s &>> 31)
        self.state = s
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z &>> 31)
    }

    /// Draw a uniform `Double` in [0, 1). Used by the simulator to apply
    /// small per-tick jitter so populations don't visibly stairstep.
    public mutating func nextUnit() -> Double {
        // 53 high bits — matches the precision of a Swift `Double`.
        let bits = next() &>> 11
        return Double(bits) / Double(1 &<< 53)
    }

    /// Draw a signed jitter centred on 0 in [-magnitude, +magnitude).
    public mutating func nextJitter(magnitude: Double) -> Double {
        (nextUnit() * 2.0 - 1.0) * magnitude
    }
}
