import Foundation
import Observation
import ForgeAccessibility

/// MainActor `@Observable` wrapper around ForgeAccessibility's
/// `SessionTimerService` actor. Adapts the actor's async API for direct
/// SwiftUI consumption while keeping the actor's authoritative `UserDefaults`
/// daily-time tracking intact.
///
/// Driven by `AppSettings.dailySessionCap` — when the parent picks a 30 / 45
/// / 60 min cap (or `.unlimited`), the coordinator (re)builds the underlying
/// `SessionTimerConfig` so the cap takes effect on the next call to
/// `start()`. `.unlimited` collapses the cap to 24h so the timer never fires
/// a `dailyLimitReached` event; the inactive coordinator is idempotent.
///
/// Per `Docs/FEATURE_PLAN.md` § Parental Controls, the soft daily-cap
/// overlay surfaces when `isDailyLimitReached == true`. It does NOT
/// force-quit the app — the overlay is a gentle pause suggestion in the
/// trauma-safe register established by the rest of engagement-foundation
/// surfaces (`SessionNudgeOverlay` / `WelcomeBackOverlay` / etc.).
///
/// Per `.claude/rules/age-assurance.md` § Portfolio Status the kid's
/// activity stays on-device only — the actor's `UserDefaults` cumulative
/// daily-time bucket is a counts-only signal, never an event log.
@MainActor
@Observable
public final class DailyTimeCoordinator {
    public private(set) var dailyElapsedMinutes: Double = 0
    public private(set) var dailyRemainingMinutes: Double = 0
    public private(set) var isDailyLimitReached: Bool = false
    public private(set) var isApproachingDailyLimit: Bool = false

    /// Last `AppSettings.dailySessionCap` we built the timer against. Drives
    /// the rebuild path when the parent changes the cap mid-session.
    public private(set) var activeCap: DailySessionCap

    private var timer: SessionTimerService
    private let keyPrefix: String

    public init(
        cap: DailySessionCap = .thirty,
        keyPrefix: String = "MicrobeLab.dailyTime"
    ) {
        self.activeCap = cap
        self.keyPrefix = keyPrefix
        // SessionTimerService defaults to `UserDefaults.standard`; keeping
        // it inside the actor's init avoids the Swift 6 sending diagnostic
        // that fires when a `@MainActor` class hands a non-Sendable
        // `UserDefaults` reference across the actor boundary. Tests cover
        // the actor directly via ForgeKit's own suite; the wrapper is
        // pure plumbing.
        self.timer = SessionTimerService(
            config: DailyTimeCoordinator.config(for: cap),
            keyPrefix: keyPrefix
        )
    }

    /// Starts the active session. Idempotent — calling twice in a row keeps
    /// the second start.
    public func startSession() async {
        await timer.start()
        await refresh()
        DebugLog.lifecycle("DailyTimeCoordinator — startSession (cap=\(activeCap.rawValue))")
    }

    /// Ends the active session, flushing the elapsed time into the daily
    /// accumulator.
    public func endSession() async {
        await timer.endSession()
        await refresh()
        DebugLog.lifecycle("DailyTimeCoordinator — endSession (dailyElapsed=\(dailyElapsedMinutes)m)")
    }

    /// Pause / resume mirror the underlying actor.
    public func pause() async {
        await timer.pause()
        await refresh()
    }

    public func resume() async {
        await timer.resume()
        await refresh()
    }

    /// Re-read the actor's projected values into the observable surface.
    /// Call from a `TimelineView(.periodic(by:))` or per-event hook; the
    /// actor stays the source of truth.
    public func refresh() async {
        dailyElapsedMinutes = await timer.dailyElapsedMinutes
        dailyRemainingMinutes = await timer.dailyRemainingMinutes
        isDailyLimitReached = await timer.isDailyLimitReached
        isApproachingDailyLimit = await timer.isApproachingDailyLimit
    }

    /// Rebuild the underlying timer when the parent changes
    /// `AppSettings.dailySessionCap`. Preserves the cumulative daily-time
    /// bucket because the actor reads it from the same `UserDefaults` key
    /// prefix; we just swap the cap on the in-memory config.
    public func updateCap(_ cap: DailySessionCap) async {
        guard cap != activeCap else { return }
        DebugLog.state("DailyTimeCoordinator — cap \(activeCap.rawValue) → \(cap.rawValue)")
        activeCap = cap
        timer = SessionTimerService(
            config: DailyTimeCoordinator.config(for: cap),
            keyPrefix: keyPrefix
        )
        await timer.start()
        await refresh()
    }

    /// Translate the kid-facing cap into a `SessionTimerConfig`.
    /// `.unlimited` collapses to a 24h cap so the timer's
    /// `isDailyLimitReached` never fires; warning thresholds are clamped to
    /// safe values relative to the cap.
    private static func config(for cap: DailySessionCap) -> SessionTimerConfig {
        let dailyLimit = cap.minutes ?? (24 * 60)
        let sessionLimit = min(dailyLimit, 30) // soft cap per-session within the daily cap
        let warning = max(1, min(5, dailyLimit / 10))
        return SessionTimerConfig(
            maxSessionMinutes: sessionLimit,
            warningAtMinutesRemaining: [warning, 1],
            dailyTimeLimitMinutes: dailyLimit,
            dailyWarningThresholdMinutes: warning
        )
    }
}
