import Testing
import Foundation
import Models
import ForgePedagogy
@testable import SharedUI

@Suite("QuizMachine hint progression (ForgePedagogy.HintTier)")
struct QuizMachineHintTests {

    private func makeQuestion(
        prompt: String = "Which microbe ferments lactose?",
        correctIndex: Int = 0,
        explanation: String = "Lactobacillus ferments lactose into lactic acid. The fermentation cools the gut's pH and crowds out opportunists.",
        standard: String? = "NGSS MS-LS1-1"
    ) -> Question {
        Question(
            id: UUID(),
            prompt: prompt,
            choices: ["Lactobacillus", "E.coli", "Yeast", "Virus"],
            correctIndex: correctIndex,
            explanation: explanation,
            curriculumStandard: standard
        )
    }

    @Test("fresh machine has no hint tier and the first requestable tier is .vague")
    func freshMachine_noHintTier_firstRequestableVague() {
        let machine = QuizMachine(totalQuestions: 5)
        #expect(machine.requestedHintTier == nil)
        #expect(machine.nextRequestableHintTier == .vague)
        #expect(machine.hintsUsedCount == 0)
    }

    @Test("requestNextHint progresses vague → medium → specific then stops")
    func requestNextHint_progressesAcrossThreeTiers() {
        var machine = QuizMachine(totalQuestions: 5)
        #expect(machine.requestNextHint() == .vague)
        #expect(machine.requestedHintTier == .vague)
        #expect(machine.nextRequestableHintTier == .medium)
        #expect(machine.hintsUsedCount == 1) // single per-question bump

        #expect(machine.requestNextHint() == .medium)
        #expect(machine.requestedHintTier == .medium)
        #expect(machine.hintsUsedCount == 1) // does NOT re-bump within same question

        #expect(machine.requestNextHint() == .specific)
        #expect(machine.requestedHintTier == .specific)
        #expect(machine.nextRequestableHintTier == nil)

        // No further escalation after .specific
        #expect(machine.requestNextHint() == nil)
        #expect(machine.requestedHintTier == .specific)
    }

    @Test("advance clears the per-question hint tier but preserves the cumulative count")
    func advance_clearsTier_preservesCount() {
        let q = makeQuestion()
        var machine = QuizMachine(totalQuestions: 3)
        machine.select(0)
        machine.requestNextHint()
        machine.requestNextHint()
        #expect(machine.requestedHintTier == .medium)
        #expect(machine.hintsUsedCount == 1)
        machine.reveal(against: q)
        machine.advance()
        #expect(machine.requestedHintTier == nil)
        #expect(machine.nextRequestableHintTier == .vague)
        #expect(machine.hintsUsedCount == 1, "cumulative count survives advance")

        // Request a hint on the new question — count bumps to 2.
        machine.requestNextHint()
        #expect(machine.hintsUsedCount == 2)
    }

    @Test("nextRequestableHintTier returns nil after reveal (kid already saw the answer)")
    func nextRequestableHintTier_nilAfterReveal() {
        let q = makeQuestion()
        var machine = QuizMachine(totalQuestions: 3)
        machine.select(0)
        machine.reveal(against: q)
        #expect(machine.revealed == true)
        #expect(machine.nextRequestableHintTier == nil)
        #expect(machine.requestNextHint() == nil)
    }

    @Test("reset clears the hint state completely")
    func reset_clearsHintState() {
        var machine = QuizMachine(totalQuestions: 3)
        machine.requestNextHint()
        machine.requestNextHint()
        machine.reset()
        #expect(machine.requestedHintTier == nil)
        #expect(machine.hintsUsedCount == 0)
        #expect(machine.nextRequestableHintTier == .vague)
    }

    // MARK: - QuestionHintStrategy

    @Test("vague hint references the curriculum standard when present")
    func vagueHint_includesStandard() {
        let q = makeQuestion(standard: "NGSS MS-LS1-1")
        let hint = QuestionHintStrategy.hint(for: .vague, in: q)
        #expect(hint.contains("MS-LS1-1") || hint.contains("ms-ls1-1"))
    }

    @Test("vague hint falls back to a generic nudge when no standard is supplied")
    func vagueHint_fallbackWhenNoStandard() {
        let q = makeQuestion(standard: nil)
        let hint = QuestionHintStrategy.hint(for: .vague, in: q)
        #expect(hint.contains("Re-read"))
    }

    @Test("medium hint returns the first sentence of the explanation")
    func mediumHint_firstSentence() {
        let q = makeQuestion(
            correctIndex: 1, // E.coli — doesn't appear in the explanation
            explanation: "Sugar gives opportunists an edge. Fiber-fermenters lose ground when the diet swings sweet."
        )
        let hint = QuestionHintStrategy.hint(for: .medium, in: q)
        #expect(hint == "Sugar gives opportunists an edge.")
    }

    @Test("medium hint elides the correct-choice phrase to avoid leaking the answer")
    func mediumHint_elidesCorrectAnswer() {
        let q = makeQuestion(
            correctIndex: 0,
            explanation: "Lactobacillus ferments lactose into lactic acid."
        )
        let hint = QuestionHintStrategy.hint(for: .medium, in: q)
        #expect(!hint.contains("Lactobacillus"))
        #expect(hint.contains("____"))
    }

    @Test("specific hint returns the full explanation verbatim")
    func specificHint_fullExplanation() {
        let q = makeQuestion(explanation: "Lacto ferments lactose into lactic acid. The fermentation cools the gut's pH.")
        let hint = QuestionHintStrategy.hint(for: .specific, in: q)
        #expect(hint == "Lacto ferments lactose into lactic acid. The fermentation cools the gut's pH.")
    }

    @Test("specific hint gracefully handles empty explanation")
    func specificHint_emptyExplanationFallback() {
        let q = makeQuestion(explanation: "")
        let hint = QuestionHintStrategy.hint(for: .specific, in: q)
        #expect(hint.contains("Tap Check"))
    }
}
