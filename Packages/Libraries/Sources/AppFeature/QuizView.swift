import SwiftUI
import Models
import Services
import SharedUI
import ForgeCelebration
import ForgePedagogy

/// Multiple-choice quiz surface for a `QuestionKit`. Per
/// `.claude/rules/state-machines.md` § `*Machine` Structs, view-local state
/// lives in `QuizMachine` (SharedUI). Per `.claude/rules/swiftui.md` no
/// `AnyView` / no parameterless `.animation()`.
public struct QuizView: View {
    let kit: QuestionKit
    let gamification: GamificationService?
    let celebration: CelebrationCoordinator?
    @State private var machine: QuizMachine
    @State private var hasAwardedCompletionXP = false

    public init(
        kit: QuestionKit,
        gamification: GamificationService? = nil,
        celebration: CelebrationCoordinator? = nil
    ) {
        self.kit = kit
        self.gamification = gamification
        self.celebration = celebration
        _machine = State(initialValue: QuizMachine(totalQuestions: kit.questions.count))
    }

    public var body: some View {
        VStack(spacing: 20) {
            header
            if machine.isComplete {
                completionPanel
            } else {
                questionPanel
            }
        }
        .padding()
        .navigationTitle(Text(verbatim: kit.title))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            DebugLog.lifecycle("QuizView onAppear; kit=\(kit.slug) questions=\(kit.questions.count)")
        }
        .onChange(of: machine.isComplete) { _, newValue in
            guard newValue, !hasAwardedCompletionXP else { return }
            hasAwardedCompletionXP = true
            let allCorrect = machine.correctCount == kit.questions.count
            if let gamification {
                let baseXP = 10 * machine.correctCount
                gamification.awardXP(baseXP, reason: "quiz kit \(kit.slug)")
                gamification.evaluateAchievements { definition in
                    switch definition.id {
                    case MicrobeLabAchievements.firstQuiz.id: return true
                    case MicrobeLabAchievements.quizPerfect.id: return allCorrect
                    default: return false
                    }
                }
            }
            // Proportional celebration per Docs/FEATURE_PLAN.md § Delight &
            // Polish — perfect kit gets an epic tier (full-screen Lottie
            // fallback to emoji + headline); a "got most of them" finish gets
            // a major; a low score lands a small acknowledgement so the kid
            // never sees a flatline. ForgeCelebration's cooldown +
            // tier-precedence rules keep this from stacking with the
            // immune-game wave-clear.
            if let celebration {
                if allCorrect {
                    celebration.perfectRound(count: kit.questions.count)
                } else if machine.correctCount >= kit.questions.count - 1 {
                    celebration.celebrate(.major, message: "Nice work — \(machine.correctCount) of \(kit.questions.count)", emoji: "🎉")
                } else {
                    celebration.celebrate(.small, message: "Kit complete", emoji: "✓")
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(verbatim: kit.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: progressLabel)
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
            ProgressView(value: machine.isComplete ? 1.0 : machine.progressFraction)
                .progressViewStyle(.linear)
        }
    }

    private var progressLabel: String {
        if machine.isComplete {
            return "\(machine.correctCount) / \(kit.questions.count)"
        }
        return "\(machine.currentIndex + 1) / \(kit.questions.count)"
    }

    // MARK: - Question

    private var currentQuestion: Question {
        kit.questions[machine.currentQuestionIndex]
    }

    private var questionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: currentQuestion.prompt)
                .font(.title3)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(currentQuestion.choices.enumerated()), id: \.offset) { index, choice in
                choiceRow(index: index, label: choice)
            }

            if let tier = machine.requestedHintTier, !machine.revealed {
                hintCard(for: tier)
            }

            if machine.revealed {
                explanationCard
            }

            actionRow
        }
    }

    private func hintCard(for tier: ForgePedagogy.HintTier) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb")
                .foregroundStyle(.yellow)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: tier.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(verbatim: QuestionHintStrategy.hint(for: tier, in: currentQuestion))
                    .font(.callout)
            }
        }
        .padding(12)
        .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }

    private func choiceRow(index: Int, label: String) -> some View {
        Button {
            machine.select(index)
        } label: {
            HStack {
                Image(systemName: choiceGlyph(for: index))
                    .imageScale(.large)
                Text(verbatim: label)
                    .font(.callout)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(choiceBackground(for: index), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(machine.revealed)
        .accessibilityHint(machine.revealed ? "Answer locked" : "Tap to select this answer")
    }

    private func choiceGlyph(for index: Int) -> String {
        if machine.revealed {
            if index == currentQuestion.correctIndex { return "checkmark.circle.fill" }
            if index == machine.selectedChoiceIndex { return "xmark.circle.fill" }
            return "circle"
        }
        return machine.selectedChoiceIndex == index ? "largecircle.fill.circle" : "circle"
    }

    private func choiceBackground(for index: Int) -> Color {
        if machine.revealed {
            if index == currentQuestion.correctIndex { return .green.opacity(0.15) }
            if index == machine.selectedChoiceIndex { return .red.opacity(0.15) }
        } else if machine.selectedChoiceIndex == index {
            return .accentColor.opacity(0.15)
        }
        return Color.gray.opacity(0.08)
    }

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .padding(.top, 2)
            Text(verbatim: currentQuestion.explanation)
                .font(.callout)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .transition(.opacity)
    }

    private var actionRow: some View {
        HStack {
            if machine.comboCount >= 2 {
                Label("Streak \(machine.comboCount)", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            Spacer()
            if !machine.revealed, let nextTier = machine.nextRequestableHintTier {
                Button {
                    let granted = machine.requestNextHint()
                    DebugLog.state("QuizView hint requested \(machine.currentIndex): tier=\(granted?.displayName ?? "none")")
                } label: {
                    Label(nextTier.displayName, systemImage: "lightbulb")
                }
                .buttonStyle(.glass)
                .accessibilityHint("Reveals a hint for this question — you can always pick on your own first")
            }
            if !machine.revealed {
                Button("Check") {
                    machine.reveal(against: currentQuestion)
                    DebugLog.state("QuizView reveal \(machine.currentIndex): correct=\(machine.selectedChoiceIndex == currentQuestion.correctIndex)")
                }
                .buttonStyle(.glassProminent)
                .disabled(machine.selectedChoiceIndex == nil)
            } else {
                Button(machine.currentIndex + 1 < kit.questions.count ? "Next" : "Finish") {
                    machine.advance()
                    DebugLog.state("QuizView advance to \(machine.currentIndex)")
                }
                .buttonStyle(.glassProminent)
            }
        }
    }

    // MARK: - Completion

    private var completionPanel: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(.tint)
            Text("Kit complete!")
                .font(.title2.weight(.semibold))
            Text(verbatim: "You got \(machine.correctCount) of \(kit.questions.count) right.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if machine.maxCombo >= 2 {
                Label("Best streak: \(machine.maxCombo)", systemImage: "flame.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            if machine.hintsUsedCount > 0 {
                // Trauma-informed framing per
                // `.claude/rules/trauma-informed-content.md`: asking for help is
                // celebrated, never penalized.
                Label("Asked for help on \(machine.hintsUsedCount) — that's how learning works", systemImage: "lightbulb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Play again") {
                machine.reset()
            }
            .buttonStyle(.glass)
        }
        .padding(.vertical, 12)
    }
}
