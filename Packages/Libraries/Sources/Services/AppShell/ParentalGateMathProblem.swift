import Foundation
import ForgeMath

/// Adult-tier subtraction problem used by `ParentalGateView` to confirm a
/// grown-up is present before destructive or external-link affordances are
/// exposed.
///
/// Wraps ForgeMath's `Rational` + `AnswerValidator` so the gate accepts
/// equivalent answer forms (e.g. `"55"` vs `"55.0"`) without the view layer
/// re-implementing parsing or tolerance. Per `.claude/rules/age-assurance.md`,
/// parental gates are required for external links and data-sharing
/// permissions.
public nonisolated struct ParentalGateMathProblem: Sendable, Equatable {
    public let firstNumber: Int
    public let secondNumber: Int

    public init(firstNumber: Int, secondNumber: Int) {
        self.firstNumber = firstNumber
        self.secondNumber = secondNumber
    }

    /// Generates a fresh adult-tier subtraction problem.
    public static func random() -> ParentalGateMathProblem {
        ParentalGateMathProblem(
            firstNumber: Int.random(in: 12...49),
            secondNumber: Int.random(in: 5...11)
        )
    }

    /// Display the prompt in the gate's "N − M = ?" register.
    public var promptText: String {
        "\(firstNumber) − \(secondNumber) = ?"
    }

    /// Expected answer, expressed as ForgeMath's exact `Rational`.
    public var expectedAnswer: Rational {
        Rational(firstNumber - secondNumber)
    }

    /// Validate a typed answer string. Returns a ForgeMath
    /// `AnswerValidation` so `.correct` and `.equivalent` both gate-pass
    /// (the kid's grown-up shouldn't have to type "55" specifically — "55.0"
    /// or "55/1" or "5 + 50" should all count).
    public func validate(answerText: String) -> AnswerValidation {
        let validator = AnswerValidator(
            tolerance: .standard,
            acceptEquivalent: true
        )
        return validator.validate(
            expected: "\(firstNumber - secondNumber)",
            actual: answerText
        )
    }

    /// Convenience: did the answer pass the gate?
    public func isAccepted(answerText: String) -> Bool {
        validate(answerText: answerText).isAccepted
    }
}
