import Foundation
import Models
import ForgePedagogy

/// View-local state machine for the QuizView per `.claude/rules/state-machines.md`.
///
/// Pure value type with a required `reset()` that fully re-assigns `self`.
/// `nonisolated` so it slots into SwiftUI views without an isolation hop.
public nonisolated struct QuizMachine: Sendable, Equatable {
    // MARK: - Progress
    public var currentIndex: Int
    public var correctCount: Int
    public var selectedChoiceIndex: Int?
    public var revealed: Bool
    public var isComplete: Bool

    // MARK: - Streak
    public var comboCount: Int
    public var maxCombo: Int

    // MARK: - Scaffolding (ForgePedagogy.HintTier)
    /// Highest hint tier requested for the CURRENT question. Cleared on
    /// `advance()` so each question starts hint-free. `nil` means the kid
    /// hasn't asked for a hint yet on this question.
    public var requestedHintTier: HintTier?
    /// Running count of questions where the kid requested ANY hint tier.
    /// Surfaces a soft summary on the completion panel ("you asked for help
    /// on N — that's how learning works") and is available to gamification
    /// for follow-up curves. Trauma-informed: never framed as a penalty.
    public var hintsUsedCount: Int

    public let totalQuestions: Int

    public init(totalQuestions: Int) {
        self.totalQuestions = totalQuestions
        self.currentIndex = 0
        self.correctCount = 0
        self.selectedChoiceIndex = nil
        self.revealed = false
        self.isComplete = totalQuestions == 0
        self.comboCount = 0
        self.maxCombo = 0
        self.requestedHintTier = nil
        self.hintsUsedCount = 0
    }

    public mutating func reset() {
        self = QuizMachine(totalQuestions: totalQuestions)
    }

    // MARK: - Hint progression

    /// The next hint tier the kid can request. Returns `nil` when the kid
    /// has already asked for `.specific` (no further escalation available)
    /// OR the question has been revealed.
    public var nextRequestableHintTier: HintTier? {
        guard !revealed, !isComplete else { return nil }
        switch requestedHintTier {
        case nil: return .vague
        case .vague: return .medium
        case .medium: return .specific
        case .specific: return nil
        }
    }

    /// Advances `requestedHintTier` to the next tier. Bumps `hintsUsedCount`
    /// the first time a hint is requested for the current question (subsequent
    /// escalations on the same question don't re-bump). Returns the newly
    /// requested tier, or `nil` if no further escalation is possible.
    @discardableResult
    public mutating func requestNextHint() -> HintTier? {
        guard let next = nextRequestableHintTier else { return nil }
        if requestedHintTier == nil {
            hintsUsedCount += 1
        }
        requestedHintTier = next
        return next
    }

    /// Returns the current question index clamped to the bundle bounds.
    public var currentQuestionIndex: Int {
        max(0, min(currentIndex, totalQuestions - 1))
    }

    public var progressFraction: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(currentIndex) / Double(totalQuestions)
    }

    public mutating func select(_ index: Int) {
        guard !revealed, !isComplete else { return }
        selectedChoiceIndex = index
    }

    /// Reveal the current question's correctness. Returns `true` if the
    /// selected answer is correct.
    @discardableResult
    public mutating func reveal(against question: Question) -> Bool {
        guard !revealed else { return question.correctIndex == selectedChoiceIndex }
        revealed = true
        let correct = selectedChoiceIndex == question.correctIndex
        if correct {
            correctCount += 1
            comboCount += 1
            maxCombo = Swift.max(maxCombo, comboCount)
        } else {
            comboCount = 0
        }
        return correct
    }

    public mutating func advance() {
        guard revealed else { return }
        if currentIndex + 1 >= totalQuestions {
            isComplete = true
            currentIndex = totalQuestions
        } else {
            currentIndex += 1
        }
        selectedChoiceIndex = nil
        revealed = false
        // Clear hint-tier state for the new question. Per-question hint
        // counter is preserved in `hintsUsedCount` for the completion panel.
        requestedHintTier = nil
    }
}
