import Foundation
import ForgeSensory

/// Thin MainActor wrapper around `ForgeSensory.SensoryPalette` so SwiftUI
/// views can inject + share one palette across the kid's session without
/// each consumer instantiating its own. Per `.claude/rules/forgekit.md`
/// § Module Catalog → ForgeSensory: the palette routes haptic + audio
/// dispatch through a single seam keyed off `SensoryEvent`.
///
/// MicrobeLab's wire:
/// - QuizView fires `.correctAnswer` / `.incorrectAnswer` on reveal
/// - QuizView + MicrobiomeView + ImmuneGameView fire `.achievement` per
///   ForgeGamification unlock (mirrors the celebration coordinator's
///   badge-earned cue but on the haptic/audio axis)
/// - ImmuneGameView fires `.challengeComplete` on full-run clear
///
/// Audio playback stays disabled in Phase 1 (`audioEngine` + `sfxPlayer`
/// both nil so the palette only fires the haptic side + sets `lastEvent`).
/// Once labsmith ships the SFX pack per `.claude/rules/forgekit.md`
/// § Asset generation ownership, a follow-up PR plumbs the SFX dispatch
/// closure through this coordinator.
///
/// Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Juice layer" — visual
/// + audio + haptic trifecta on every interaction. The visual is the
/// existing `CelebrationCoordinator`; the audio + haptic axis lands here.
@MainActor
@Observable
public final class SensoryPaletteCoordinator: Sendable {
    private let palette: SensoryPalette
    public private(set) var lastEvent: SensoryEvent?
    public private(set) var firedCount: Int = 0

    public init(palette: SensoryPalette? = nil) {
        self.palette = palette ?? SensoryPalette()
    }

    /// Routes the event into the palette + mirrors `lastEvent` on the
    /// coordinator so SwiftUI consumers can observe via `@Bindable` / direct
    /// read. `firedCount` is a monotonic counter — primarily for tests.
    public func fire(_ event: SensoryEvent) {
        palette.fire(event)
        lastEvent = event
        firedCount += 1
        DebugLog.state("SensoryPaletteCoordinator fired \(event)")
    }
}
