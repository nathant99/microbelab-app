import Foundation

/// Snapshot of session-relevant stats surfaced in the end-of-session
/// summary card per `Docs/FEATURE_PLAN.md` § Parent Integration →
/// "Session closer — End-of-session summary with achievements + preview
/// of next session content".
///
/// Pure nonisolated value type — captured at the moment the kid taps
/// "Wrap up today" so the displayed numbers freeze. Future-session
/// activity doesn't retroactively change a summary the kid has seen.
///
/// **Trauma-informed framing**: the summary copy reads as "you did this
/// today" — never "your streak is at risk" or "X more for the next
/// milestone." Numbers are warm + concrete, not pressure tactics.
public nonisolated struct SessionSummary: Sendable, Equatable {
    public let currentLevel: Int
    public let totalXP: Int
    public let currentStreak: Int
    public let microbesDiscovered: Int
    public let achievementsEarned: Int

    public init(
        currentLevel: Int,
        totalXP: Int,
        currentStreak: Int,
        microbesDiscovered: Int,
        achievementsEarned: Int
    ) {
        self.currentLevel = currentLevel
        self.totalXP = totalXP
        self.currentStreak = currentStreak
        self.microbesDiscovered = microbesDiscovered
        self.achievementsEarned = achievementsEarned
    }

    /// Headline copy reflecting how full the kid's session feels.
    /// Trauma-safe alternates — never "you barely played" / "you played
    /// too much."
    public var headline: String {
        if microbesDiscovered >= 6 {
            return "You explored a lot today"
        }
        if microbesDiscovered >= 3 {
            return "Solid session"
        }
        return "Quiet today — that's allowed"
    }

    /// Preview hint for what's worth coming back for. Stays gentle: no
    /// "your streak will break" language; always a "next time" frame
    /// that the kid can ignore without penalty.
    public var nextSessionPreview: String {
        if microbesDiscovered == 0 {
            return "Next time, try pinching to zoom — a microbe is usually waiting around 100×."
        }
        if currentStreak == 0 {
            return "Next time, the codex remembers what you've already seen — you can pick up exactly where you left off."
        }
        return "Next time, try a different feeding mode in the microbiome puzzle. The microbes notice."
    }
}
