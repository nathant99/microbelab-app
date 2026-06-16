import Foundation
import Testing
@testable import Services

@Suite("ParentalGateMathProblem")
struct ParentalGateMathProblemTests {
    @Test func promptTextMatchesGateRegister() {
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.promptText == "42 − 7 = ?")
    }

    @Test func exactMatchIsCorrect() {
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "35"))
    }

    @Test func wrongAnswerIsRejected() {
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "34") == false)
        #expect(problem.isAccepted(answerText: "100") == false)
    }

    @Test func equivalentDecimalFormPasses() {
        // ForgeMath's AnswerValidator accepts "35.0" as equivalent to "35"
        // so the parent doesn't have to type the exact integer form.
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "35.0"))
    }

    @Test func equivalentRationalFormPasses() {
        // "35/1" is the rational form of 35 — also accepted.
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "35/1"))
    }

    @Test func whitespaceTolerated() {
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "  35  "))
    }

    @Test func emptyAnswerRejected() {
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "") == false)
    }

    @Test func nonNumericRejected() {
        let problem = ParentalGateMathProblem(firstNumber: 42, secondNumber: 7)
        #expect(problem.isAccepted(answerText: "thirty-five") == false)
        #expect(problem.isAccepted(answerText: "abc") == false)
    }

    @Test func randomProblemStaysInAdultTierBand() {
        // Adult-tier means two-digit minuend (12...49) with subtrahend (5...11)
        // so the difference is always positive and ≥ 1.
        for _ in 0..<50 {
            let problem = ParentalGateMathProblem.random()
            #expect(problem.firstNumber >= 12)
            #expect(problem.firstNumber <= 49)
            #expect(problem.secondNumber >= 5)
            #expect(problem.secondNumber <= 11)
            let diff = problem.firstNumber - problem.secondNumber
            #expect(diff >= 1)
        }
    }

    @Test func expectedAnswerMatchesArithmetic() {
        let problem = ParentalGateMathProblem(firstNumber: 30, secondNumber: 8)
        #expect(problem.expectedAnswer.numerator == 22)
        #expect(problem.expectedAnswer.denominator == 1)
    }
}
