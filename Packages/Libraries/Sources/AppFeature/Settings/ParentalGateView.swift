import Services
import SwiftUI

/// Simple math-problem parental gate. Used to confirm an adult is present
/// before destructive or external-link affordances are exposed.
///
/// Per `.claude/rules/age-assurance.md`, parental gates are required for
/// external links and data-sharing permissions. The problem is intentionally
/// adult-tier (two-digit subtraction + a wrong-attempt cooldown) so a kid
/// guessing wouldn't pass. Answer validation routes through
/// `Services.ParentalGateMathProblem`, which wraps ForgeMath's
/// `AnswerValidator` so equivalent answer forms ("55" / "55.0" / "5 + 50")
/// all pass without per-call-site parsing.
public struct ParentalGateView: View {
    @State private var problem: ParentalGateMathProblem
    @State private var answerText: String = ""
    @State private var wrongAttempts: Int = 0
    @State private var isLocked: Bool = false
    @State private var lockedUntil: Date?

    public let onPassed: () -> Void
    public let onCancel: () -> Void

    public init(onPassed: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _problem = State(initialValue: ParentalGateMathProblem.random())
        self.onPassed = onPassed
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Adult check")
                .font(.title3.weight(.semibold))
            Text("Please ask a grown-up to answer this for you.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(verbatim: problem.promptText)
                .font(.title.weight(.semibold).monospacedDigit())
                .padding(.vertical, 6)

            #if os(iOS)
            TextField("Answer", text: $answerText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
                .disabled(isLocked)
            #else
            TextField("Answer", text: $answerText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
                .disabled(isLocked)
            #endif

            if isLocked {
                Text("Try again in a moment.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if wrongAttempts > 0 {
                Text("Not quite — try again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .buttonStyle(.glass)

                Button("Confirm") {
                    handleConfirm()
                }
                .buttonStyle(.glassProminent)
                .disabled(isLocked || answerText.isEmpty)
            }
            .padding(.top, 4)
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Adult check; subtraction problem")
    }

    private func handleConfirm() {
        if problem.isAccepted(answerText: answerText) {
            onPassed()
        } else {
            wrongAttempts += 1
            answerText = ""
            if wrongAttempts >= 3 {
                isLocked = true
                lockedUntil = Date().addingTimeInterval(30)
                // 30-second cooldown — the kid can't brute-force.
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    isLocked = false
                    wrongAttempts = 0
                    // New problem, fresh attempts.
                    problem = ParentalGateMathProblem.random()
                }
            }
        }
    }
}
