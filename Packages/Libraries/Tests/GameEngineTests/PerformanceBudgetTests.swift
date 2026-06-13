import Foundation
import Testing
@testable import GameEngine
@testable import Models

/// Algorithmic perf-budget bench harness. Closes the FEATURE_PLAN.md
/// § Phase 1 → Quality "Performance profiling" remaining assertion gap:
/// the `OSSignposter` probes shipped via PR #56 expose live timing in
/// Instruments; this suite drives the same pure-value surfaces against
/// a wall-clock budget so a regression that lands without an Instruments
/// capture is still caught by the unit-test gate.
///
/// Scope vs the Instruments capture pending real-device profiling:
///
/// - **In scope here**: the algorithmic per-tick budgets for the
///   pure-value simulator + state machine + immune scene logic.
///   Run on a Mac under `swift test`; no GPU + no SpriteKit visual
///   setup; tests assert an *average* across N=200 iterations to
///   filter cold-cache / GC jitter.
/// - **NOT in scope here**: actual on-device 60fps frame budget,
///   SwiftUI body re-evaluation, SpriteKit physics, image-loading
///   latency — those still want a real-device Instruments trace
///   per `Docs/FEATURE_PLAN.md` § Phase 1 → Quality.
///
/// Budgets are deliberately generous compared to the canonical
/// `MicrobiomeSimulator.tick < 8ms` + `ZoomMachine.snap < 16ms`
/// + `MacrophagePacmanScene.advancePathogens < 8ms` thresholds. We
/// assert ~4-8× headroom so noisy CI (shared M-series build agents,
/// macOS background work) doesn't flake the gate. A real on-device
/// run typically lands at < 1ms per tick.
///
/// Per `.claude/rules/testing.md` § Crash-Resilience Defaults:
/// `nonisolated struct` suite; no `@MainActor` on the suite; pure
/// value-type fixtures; no UserDefaults; no LanguageModelSession;
/// no SwiftData; no `@unchecked Sendable`.
@Suite("PerformanceBudget")
nonisolated struct PerformanceBudgetTests {
    /// Number of timed iterations averaged per budget assertion. 200
    /// is the sweet spot: enough to absorb GC + first-call JIT
    /// warm-up; small enough to keep the test under a second on the
    /// Mac runner.
    static let iterations = 200

    /// Per-iteration budget (ms) for `MicrobiomeSimulator.tick`. The
    /// canonical 8ms target gets 4× headroom for shared-CI noise.
    static let microbiomeTickBudgetMs: Double = 32

    /// Per-iteration budget (ms) for a `ZoomMachine` boundary
    /// transition. The canonical 16ms target gets 4× headroom; in
    /// practice the pure-value transition takes microseconds.
    static let zoomTransitionBudgetMs: Double = 64

    /// Per-iteration budget (ms) for
    /// `MacrophagePacmanScene.advancePathogens(by:)`. The canonical
    /// 8ms target gets 8× headroom — the immune scene constructs an
    /// SKScene under the hood (even before `configureVisuals`) which
    /// brings a one-shot allocation cost.
    static let immuneTickBudgetMs: Double = 64

    // MARK: - MicrobiomeSimulator

    @Test func microbiomeSimulatorTickAveragesUnderBudget() {
        let microbes = makeFixtureMicrobes()
        let simulator = MicrobiomeSimulator(microbes: microbes)
        var state = MicrobiomeState.initialFiber(microbes: microbes)

        let avgMs = measureAverageMs(iterations: Self.iterations) {
            state = simulator.tick(state)
        }

        #expect(avgMs < Self.microbiomeTickBudgetMs,
                "MicrobiomeSimulator.tick averaged \(avgMs)ms — over the \(Self.microbiomeTickBudgetMs)ms budget")
    }

    @Test func microbiomeSimulatorJitterTickAveragesUnderBudget() {
        let microbes = makeFixtureMicrobes()
        let simulator = MicrobiomeSimulator(microbes: microbes)
        var state = MicrobiomeState.initialFiber(microbes: microbes)
        var rng = SeededRNG(seed: 42)

        let avgMs = measureAverageMs(iterations: Self.iterations) {
            state = simulator.tick(state, using: &rng)
        }

        #expect(avgMs < Self.microbiomeTickBudgetMs,
                "MicrobiomeSimulator.tick(using:) averaged \(avgMs)ms — over the \(Self.microbiomeTickBudgetMs)ms budget")
    }

    // MARK: - ZoomMachine

    @Test func zoomMachinePinchTransitionAveragesUnderBudget() {
        let avgMs = measureAverageMs(iterations: Self.iterations) {
            var machine = ZoomMachine()
            // Drive a full pinch-in then pinch-out sequence so the
            // measurement covers boundary-snap + consumeTransition.
            machine.applyPinch(delta: 1.1)
            machine.consumeTransition()
            machine.applyPinch(delta: 1.1)
            machine.consumeTransition()
            machine.applyPinch(delta: -1.1)
            machine.consumeTransition()
        }

        #expect(avgMs < Self.zoomTransitionBudgetMs,
                "ZoomMachine.applyPinch averaged \(avgMs)ms — over the \(Self.zoomTransitionBudgetMs)ms budget")
    }

    @Test func zoomMachineSnapAveragesUnderBudget() {
        let tiers: [ZoomTier] = [.unaided, .light, .fluorescence, .electron]
        let avgMs = measureAverageMs(iterations: Self.iterations) {
            var machine = ZoomMachine()
            for tier in tiers {
                machine.snap(to: tier)
                machine.consumeTransition()
            }
        }

        #expect(avgMs < Self.zoomTransitionBudgetMs,
                "ZoomMachine.snap averaged \(avgMs)ms — over the \(Self.zoomTransitionBudgetMs)ms budget")
    }

    // MARK: - MacrophagePacmanScene

    @MainActor
    @Test func macrophageAdvancePathogensAveragesUnderBudget() {
        let scene = MacrophagePacmanScene(size: CGSize(width: 800, height: 600), seed: 7)
        scene.spawnCurrentWave()
        // Warm-up to absorb first-call allocation cost so the
        // measured iterations reflect steady-state.
        scene.advancePathogens(by: 1.0 / 60.0)

        let avgMs = MainActor.assumeIsolated {
            measureAverageMs(iterations: Self.iterations) {
                scene.advancePathogens(by: 1.0 / 60.0)
            }
        }

        #expect(avgMs < Self.immuneTickBudgetMs,
                "MacrophagePacmanScene.advancePathogens averaged \(avgMs)ms — over the \(Self.immuneTickBudgetMs)ms budget")
    }

    @MainActor
    @Test func macrophageMoveAveragesUnderBudget() {
        let scene = MacrophagePacmanScene(size: CGSize(width: 800, height: 600), seed: 7)
        scene.spawnCurrentWave()
        let delta = Vec2(x: 3, y: 2)

        let avgMs = MainActor.assumeIsolated {
            measureAverageMs(iterations: Self.iterations) {
                scene.moveMacrophage(by: delta)
            }
        }

        #expect(avgMs < Self.immuneTickBudgetMs,
                "MacrophagePacmanScene.moveMacrophage averaged \(avgMs)ms — over the \(Self.immuneTickBudgetMs)ms budget")
    }

    // MARK: - Helpers

    /// Returns the average per-iteration wall-clock cost in
    /// milliseconds. Uses `ContinuousClock.measure` which is the
    /// portfolio-standard monotonic high-resolution timer per
    /// `.claude/rules/concurrency.md`. Discards the first iteration
    /// to absorb first-call JIT / cache warm-up costs.
    private func measureAverageMs(iterations: Int, body: () -> Void) -> Double {
        // Warm-up — the first call always pays an allocation + I-cache
        // cost we don't want to count.
        body()

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0..<iterations { body() }
        }
        let nanos = elapsed.components.attoseconds / 1_000_000_000 + elapsed.components.seconds * 1_000_000_000
        let totalMs = Double(nanos) / 1_000_000.0
        return totalMs / Double(iterations)
    }

    private func makeFixtureMicrobes() -> [MicrobeCharacter] {
        // 6 microbes — matches the Phase 1 canonical DN cast count, so
        // the bench reflects the simulator workload kids actually hit.
        let baseUUID = "00000000-0000-0000-0000-00000000000"
        let names = ["lacto", "yeast", "photo", "net", "spore", "guard"]
        return names.enumerated().map { index, slug in
            MicrobeCharacter(
                id: UUID(uuidString: baseUUID + String(index + 1))!,
                slug: slug,
                displayName: slug.capitalized,
                kingdom: .bacteria,
                role: .beneficial,
                preferredEnvironment: .colon,
                growthRate: GrowthRate(
                    onFiber: 0.5,
                    onSugar: 0.2,
                    onBalanced: 0.3,
                    onNone: -0.05
                ),
                catchphrase: "Bench fixture",
                factCard: "Bench fixture",
                firstKit: index + 1
            )
        }
    }
}

private extension MicrobiomeState {
    /// Initial fiber-feeding state seeded with non-zero populations so
    /// the simulator drives the full per-microbe path through every
    /// tick (not the seed-from-zero special case).
    nonisolated static func initialFiber(microbes: [MicrobeCharacter]) -> MicrobiomeState {
        var populations: [UUID: Int] = [:]
        for microbe in microbes {
            populations[microbe.id] = 100
        }
        return MicrobiomeState(
            populations: populations,
            feedingMode: .fiber,
            antibioticState: .none,
            tickCount: 0,
            activeSlot: .colon
        )
    }
}
