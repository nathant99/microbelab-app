import Foundation

/// One multiple-choice question + its curriculum tag. Authored content only —
/// `.claude/rules/ai-content.md` keeps factual claims off the AI surface.
public nonisolated struct Question: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let prompt: String
    public let choices: [String]
    /// Index into `choices` for the correct answer. Encoded as Int for
    /// determinism + grep-ability.
    public let correctIndex: Int
    /// One-sentence explanation surfaced after the kid answers.
    public let explanation: String
    /// Optional NGSS / CCSS / NHES standard tag for reporting.
    public let curriculumStandard: String?

    public init(
        id: UUID,
        prompt: String,
        choices: [String],
        correctIndex: Int,
        explanation: String,
        curriculumStandard: String? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.curriculumStandard = curriculumStandard
    }

    public var correctChoice: String? {
        choices.indices.contains(correctIndex) ? choices[correctIndex] : nil
    }
}

/// A bundled question kit. One kit per topic per `Docs/FEATURE_PLAN.md` —
/// Phase 1 ships kits 01-04 (microbiology basics / microbiome / immune defense
/// / beneficial microbes).
public nonisolated struct QuestionKit: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let slug: String
    public let title: String
    public let summary: String
    public let kitNumber: Int
    public let questions: [Question]

    public init(
        id: UUID,
        slug: String,
        title: String,
        summary: String,
        kitNumber: Int,
        questions: [Question]
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.summary = summary
        self.kitNumber = kitNumber
        self.questions = questions
    }
}
