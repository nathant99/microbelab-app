import Foundation
import Models

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
    }

    public mutating func reset() {
        self = QuizMachine(totalQuestions: totalQuestions)
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
    }
}
