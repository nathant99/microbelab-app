import Foundation

/// Immune-defense run trophy — pure value-type snapshot of the kid's
/// macrophage minigame result captured at the moment they finish a run AND
/// tap "Share trophy" in `ImmuneGameView`. Future-session activity doesn't
/// retroactively change a trophy the kid has shared.
///
/// Trauma-informed posture: the trophy frames the run as quiet recognition,
/// never as competition. Headline scales with `wavesCleared`; the
/// `perfectRun` flag picks a distinct top-tier headline ONLY when every wave
/// was cleared with zero pathogens remaining. Subline never compares the
/// kid's score to anyone else's, never says "you almost", never references
/// any prior run as failure.
///
/// Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Share-worthy moments":
/// codex completion certificates (`CodexCertificate`) + immune-game high-
/// score trophies are the canonical share-worthy surfaces; this value type
/// closes the immune-defense axis. Mirrors the `CodexCertificate` API
/// surface so `ShareLink` + `ImageRenderer` integration in
/// `ImmuneDefenseTrophySheet` lifts the same shape verbatim.
public nonisolated struct ImmuneDefenseTrophy: Sendable, Equatable, Codable {
    /// The kid's display name (defaults to "Explorer" when not set per
    /// `PlayerProgressData.displayName`).
    public let displayName: String
    /// Number of waves the kid cleared during this run.
    public let wavesCleared: Int
    /// Total waves available in the run at the moment the trophy is captured.
    public let totalWaves: Int
    /// Final score at the moment the trophy is captured.
    public let finalScore: Int
    /// True when every wave was cleared AND zero pathogens remained on the
    /// final wave. This is the same gate `MasteryMomentDetector
    /// .recordDefenseRunComplete(wavesCleared:pathogensRemaining:)` uses, so
    /// the trophy and the mastery moment share an "perfect run" definition.
    public let perfectRun: Bool
    /// Issue date — captured at the moment the trophy is shared.
    public let issuedAt: Date

    public init(
        displayName: String,
        wavesCleared: Int,
        totalWaves: Int,
        finalScore: Int,
        perfectRun: Bool,
        issuedAt: Date
    ) {
        self.displayName = displayName
        self.wavesCleared = wavesCleared
        self.totalWaves = totalWaves
        self.finalScore = finalScore
        self.perfectRun = perfectRun
        self.issuedAt = issuedAt
    }

    /// Headline shown at the top of the trophy. Scales warmly with progress
    /// and crowns a perfect run with a distinct top tier. Never frames low
    /// counts as failure.
    public var headline: String {
        if perfectRun && wavesCleared >= totalWaves && totalWaves > 0 {
            return "Defense Master"
        }
        if wavesCleared >= totalWaves && totalWaves > 0 {
            return "Defense Champion"
        }
        switch wavesCleared {
        case 0:
            // No waves cleared yet — the trophy frames the start as agency.
            return "Defense Cadet"
        case 1...2:
            return "Defense Apprentice"
        default:
            return "Defense Specialist"
        }
    }

    /// Subline shown beneath the headline. Trauma-informed: never frames
    /// score as competition; always frames it as a record of "you held the
    /// line through N waves".
    public var subline: String {
        if wavesCleared == 0 {
            return "Your macrophages are warmed up and waiting."
        }
        if perfectRun && wavesCleared >= totalWaves && totalWaves > 0 {
            return "Every wave clear, zero pathogens missed."
        }
        if wavesCleared >= totalWaves && totalWaves > 0 {
            return "You held the line through every wave."
        }
        let plural = wavesCleared == 1 ? "wave" : "waves"
        return "You held the line through \(wavesCleared) \(plural)."
    }

    /// Score chip label — pairs with the wavesCleared / totalWaves chip in
    /// the visual surface so the trophy reads at a glance.
    public var scoreLabel: String {
        "\(finalScore) pts"
    }

    /// Wave-progress chip label.
    public var waveLabel: String {
        "\(wavesCleared) / \(totalWaves) waves"
    }

    /// Issued-on string surfaced in the trophy footer.
    public func issuedOnLabel(calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = calendar
        return "Issued \(formatter.string(from: issuedAt))"
    }
}
