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

/// Authoring state for a question kit. Mirrors `DiseaseStoryAuthoring` +
/// `VaccineExplainerAuthoringState` per ADR-016 so the same reviewer-signoff
/// pathway covers every Phase 3+ surface where prose is reviewer-blocked.
///
/// Phase 1 + Phase 2 kits ship without this field in their JSON; the
/// QuestionKit decoder defaults missing values to `.reviewerSignedOff` so
/// already-shipped kits surface to kids unchanged.
public nonisolated enum QuestionKitAuthoring: String, Codable, Sendable, CaseIterable {
    /// Structural placeholder — metadata only. The kit must NOT surface to
    /// kids; consumer code filters via `QuestionKitService.loadAllPhase3Kits()`.
    case placeholder
    /// Draft questions authored but NOT yet reviewer-signed-off. Same gating
    /// as `.placeholder` — the kid never sees draft content.
    case draftAwaitingReview
    /// Reviewer-signed-off, kid-safe to render. This is the default for
    /// Phase 1 + Phase 2 kits (the field is omitted from their JSON and the
    /// decoder defaults to this value).
    case reviewerSignedOff
}

/// A bundled question kit. One kit per topic per `Docs/FEATURE_PLAN.md` —
/// Phase 1 ships kits 01-04 (microbiology basics / microbiome / immune defense
/// / beneficial microbes); Phase 2 ships kits 05-08 (adaptive immunity / oral
/// / skin / soil microbiome); Phase 3 ships kits 09-12 (vaccines / herd
/// immunity / hygiene / public health — placeholder-gated until reviewer
/// signoff per ADR-016).
public nonisolated struct QuestionKit: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let slug: String
    public let title: String
    public let summary: String
    public let kitNumber: Int
    public let questions: [Question]
    /// Reviewer-signoff state. Phase 1 + Phase 2 kits omit this field in
    /// their JSON and the decoder defaults it to `.reviewerSignedOff` so
    /// already-shipped kits surface to kids unchanged. Phase 3+ placeholder
    /// kits explicitly set `"authoring": "draftAwaitingReview"` until prose
    /// reviewer-signoff lands. Consumer code filters by this field — kits
    /// with non-`.reviewerSignedOff` authoring never surface to kids.
    public let authoring: QuestionKitAuthoring

    public init(
        id: UUID,
        slug: String,
        title: String,
        summary: String,
        kitNumber: Int,
        questions: [Question],
        authoring: QuestionKitAuthoring = .reviewerSignedOff
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.summary = summary
        self.kitNumber = kitNumber
        self.questions = questions
        self.authoring = authoring
    }

    private enum CodingKeys: String, CodingKey {
        case id, slug, title, summary, kitNumber, questions, authoring
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.title = try container.decode(String.self, forKey: .title)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.kitNumber = try container.decode(Int.self, forKey: .kitNumber)
        self.questions = try container.decode([Question].self, forKey: .questions)
        // Default missing field to `.reviewerSignedOff` so Phase 1 + Phase 2
        // kits (which omit the field) decode unchanged.
        self.authoring = try container.decodeIfPresent(
            QuestionKitAuthoring.self,
            forKey: .authoring
        ) ?? .reviewerSignedOff
    }
}
