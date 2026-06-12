import Foundation
import Models
import ForgePedagogy

/// Derives progressive hint text from a `Question` per
/// `ForgePedagogy.HintTier`. Pure value type per `.claude/rules/concurrency.md`
/// — `nonisolated` so QuizView (MainActor) and tests (any isolation) can use
/// it without an isolation hop.
///
/// Trauma-informed register per `.claude/rules/trauma-informed-content.md`:
/// no shame framing, no "you should have known", no time-pressure cues —
/// hints are warm nudges that surface scaffolding the kid asked for.
public nonisolated enum QuestionHintStrategy {

    /// Returns the hint text for `tier` given `question`. Trims whitespace and
    /// avoids leaking the correct answer at the `.vague` / `.medium` tiers.
    public static func hint(for tier: HintTier, in question: Question) -> String {
        switch tier {
        case .vague:
            return vagueHint(for: question)
        case .medium:
            return mediumHint(for: question)
        case .specific:
            return specificHint(for: question)
        }
    }

    /// Vague: re-read framing. Surfaces curriculum-tag context if available so
    /// the kid orients to the topic without spoiler risk.
    private static func vagueHint(for question: Question) -> String {
        if let standard = question.curriculumStandard, !standard.isEmpty {
            return "Re-read the prompt. This one's about \(standard.lowercased().replacingOccurrences(of: "ngss ", with: "")) — one phrase in the question is the key."
        }
        return "Re-read the prompt — one phrase usually stands out as the key idea."
    }

    /// Medium: the first sentence of the explanation, with the correct-answer
    /// phrase elided so the answer isn't given away if it appears verbatim.
    private static func mediumHint(for question: Question) -> String {
        let firstSentence = firstSentence(of: question.explanation)
        guard !firstSentence.isEmpty else {
            return "Think about what the prompt is really asking — what would a microbiologist look for first?"
        }
        if let correctChoice = question.correctChoice,
           !correctChoice.isEmpty,
           firstSentence.localizedCaseInsensitiveContains(correctChoice) {
            // Don't leak the answer at .medium tier — fall back to the
            // sentence with the correct-choice phrase elided.
            return elide(correctChoice, in: firstSentence)
        }
        return firstSentence
    }

    /// Specific: the full explanation — same surface the QuizView shows after
    /// a reveal. At the .specific tier the kid has explicitly asked for the
    /// answer-shaped help, so leaking the choice text is appropriate.
    private static func specificHint(for question: Question) -> String {
        let trimmed = question.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? "Tap Check when you're ready — we'll walk through it after."
            : trimmed
    }

    // MARK: - Helpers

    /// Returns the first sentence (up to + including the terminating
    /// punctuation) of `text`, or an empty string if `text` has no
    /// sentence-terminating punctuation in the first 240 characters.
    private static func firstSentence(of text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let terminators: Set<Character> = [".", "!", "?"]
        var current = ""
        for char in trimmed {
            current.append(char)
            if terminators.contains(char) {
                return current.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // No terminator — return the whole string (single short clause).
        return trimmed
    }

    /// Replaces case-insensitive occurrences of `needle` in `haystack` with
    /// `"____"` so the answer text doesn't leak at the medium tier.
    private static func elide(_ needle: String, in haystack: String) -> String {
        guard !needle.isEmpty else { return haystack }
        let range = haystack.range(of: needle, options: .caseInsensitive)
        guard let range else { return haystack }
        return haystack.replacingCharacters(in: range, with: "____")
    }
}
