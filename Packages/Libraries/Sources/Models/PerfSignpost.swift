import Foundation
import os

/// Canonical OSSignposter emitter for MicrobeLab perf instrumentation.
///
/// Lives in Models so every target (Services / GameEngine / SharedUI /
/// AppFeature / AIMentor) can call it without growing the SPM dep graph.
/// Per `.claude/rules/spm-architecture.md` § "Keep target dependency edges
/// minimal" — a leaf-target utility avoids cascading edges across the
/// graph just to thread a signpost.
///
/// Per `.claude/rules/debug-logging.md` § Performance instrumentation:
/// "Wrap any operation > ~100ms in `signposter.beginInterval(...)` /
/// `.endInterval(...)`. Free for release builds — signposts are part of
/// Apple's unified logging and use the same auto-managed store." Per
/// `Docs/FEATURE_PLAN.md` Phase 1 quality exit criteria: microscope tier
/// transition target < 16ms; simulator tick target < 8ms. Signposts
/// surface in Instruments so a regression is visible without rebuilding
/// the timing harness.
///
/// Subsystem is unique per category so an Instruments filter can target a
/// single concern (`MicrobeLab.zoom` for the tier-swap flow,
/// `MicrobeLab.simulator` for the per-tick budget).
///
/// Usage:
/// ```
/// let state = PerfSignpost.zoomTransition.begin(name: "snap.fluorescence")
/// // ... transition work ...
/// PerfSignpost.zoomTransition.end(name: "snap.fluorescence", state)
/// ```
///
/// When the work is a single expression, prefer the `interval(_:work:)`
/// helper for begin/end pairing safety.
public nonisolated enum PerfSignpost: Sendable {
    public static let zoomTransition = Channel(subsystem: "com.microbelab.app", category: "zoom")
    public static let simulatorTick = Channel(subsystem: "com.microbelab.app", category: "simulator")
    public static let immuneWave = Channel(subsystem: "com.microbelab.app", category: "immune")

    /// Thin wrapper that lets value-type call sites emit signposts without
    /// constructing an `OSSignposter` directly. `Sendable`-safe because
    /// `OSSignposter` is thread-safe per Apple's documentation.
    public struct Channel: Sendable {
        public let signposter: OSSignposter

        public init(subsystem: String, category: String) {
            self.signposter = OSSignposter(subsystem: subsystem, category: category)
        }

        /// Begin an interval; returns the opaque state to thread to `.end`.
        public func begin(name: StaticString) -> OSSignpostIntervalState {
            signposter.beginInterval(name)
        }

        /// End a previously-begun interval.
        public func end(name: StaticString, _ state: OSSignpostIntervalState) {
            signposter.endInterval(name, state)
        }

        /// Synchronous bracketed interval — preferred over manual `begin` /
        /// `end` because the closure form guarantees the matching `end` even
        /// when the work throws.
        public func interval<T>(_ name: StaticString, work: () throws -> T) rethrows -> T {
            let state = signposter.beginInterval(name)
            defer { signposter.endInterval(name, state) }
            return try work()
        }
    }
}
