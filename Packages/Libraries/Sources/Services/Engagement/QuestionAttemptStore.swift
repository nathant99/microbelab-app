import Foundation
import Observation
import Models
import ForgeModels
import ForgeReporting

/// One persisted record of a kid answering one quiz question. PII-safe:
/// the kid's identifier never appears — only the question ID (UUID) +
/// kit slug + standard tag + correctness + timestamp. Per
/// `.claude/rules/age-assurance.md` § Portfolio Status the attempt log
/// stays on-device, with bounded capacity to keep UserDefaults under the
/// 100KB sweet spot for synchronous reads.
public nonisolated struct QuestionAttempt: Codable, Sendable, Equatable {
    public let questionID: UUID
    public let kitSlug: String
    /// Optional curriculum tag (e.g., "MS-LS1-1" or "NHES 1"). Some
    /// authored questions ship without a tag — those still log so the
    /// total-attempts count stays accurate even without a proficiency
    /// contribution.
    public let curriculumStandard: String?
    public let wasCorrect: Bool
    public let answeredAt: Date

    public init(
        questionID: UUID,
        kitSlug: String,
        curriculumStandard: String?,
        wasCorrect: Bool,
        answeredAt: Date
    ) {
        self.questionID = questionID
        self.kitSlug = kitSlug
        self.curriculumStandard = curriculumStandard
        self.wasCorrect = wasCorrect
        self.answeredAt = answeredAt
    }
}

/// MainActor `@Observable` UserDefaults-backed log of per-question quiz
/// attempts. Powers the parent-facing "Strengths / Growth Areas"
/// per-standard proficiency surface in `ProgressReportView`.
///
/// Storage: a JSON-encoded array under a single UserDefaults key. Cap
/// `maxAttempts` defaults to 500 (FIFO eviction); at ~120 bytes per
/// encoded record this stays well under the 100KB UserDefaults sweet
/// spot. Per `.claude/rules/age-assurance.md` § Portfolio Status: counts
/// + UUIDs + slugs + booleans only — never PII.
///
/// Wiring path:
/// - `QuizView` calls `recordAttempt(question:kitSlug:wasCorrect:)` on
///   every `.reveal(against:)` boundary so each kid answer logs exactly
///   once (revealed + advance is the question-boundary in the FSM).
/// - `ProgressReportService.reportData(for:grade:)` reads the store's
///   `proficiencies(matching:)` derivation + threads it through
///   `StudentReportData.standardProficiencies` so
///   `ForgeReportGenerator.parentConferenceReport(_:)` surfaces real
///   Strengths / Growth Areas (was empty placeholder pre-this PR).
@MainActor
@Observable
public final class QuestionAttemptStore {
    public static let userDefaultsKey = "com.microbelab.quiz.attempts"

    /// Maximum number of attempt records retained. FIFO eviction past
    /// this cap — the oldest attempt drops as a new one lands. Picked at
    /// 500 because: a Phase-1 quiz kit ships 5-6 questions, so 500 covers
    /// ~85 distinct kit completions before any eviction. Sufficient for
    /// a parent report that scopes "all-time" without going unbounded.
    public static let defaultMaxAttempts = 500

    public private(set) var attempts: [QuestionAttempt]

    private let defaults: UserDefaults
    private let maxAttempts: Int

    public init(
        defaults: UserDefaults = .standard,
        maxAttempts: Int = defaultMaxAttempts
    ) {
        self.defaults = defaults
        self.maxAttempts = maxAttempts
        if let data = defaults.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([QuestionAttempt].self, from: data) {
            self.attempts = decoded
        } else {
            self.attempts = []
        }
    }

    /// Append one attempt record + FIFO-evict if the cap was crossed.
    /// `answeredAt` defaults to `.now` so callers don't need to thread a
    /// clock; pass an explicit Date for testability.
    public func recordAttempt(
        question: Question,
        kitSlug: String,
        wasCorrect: Bool,
        answeredAt: Date = .now
    ) {
        let attempt = QuestionAttempt(
            questionID: question.id,
            kitSlug: kitSlug,
            curriculumStandard: question.curriculumStandard,
            wasCorrect: wasCorrect,
            answeredAt: answeredAt
        )
        attempts.append(attempt)
        if attempts.count > maxAttempts {
            attempts.removeFirst(attempts.count - maxAttempts)
        }
        persist()
    }

    /// Wipe persisted state. Test-only — the production surface never
    /// shrinks a kid's attempt log.
    public func clearForTesting() {
        attempts.removeAll()
        defaults.removeObject(forKey: Self.userDefaultsKey)
    }

    /// Derive `StandardProficiency` rows for each standard in `standards`
    /// that has at least one matching attempt. Matches on the standard's
    /// `code` (e.g., "MS-LS1-1") against the attempt's
    /// `curriculumStandard` string field. Standards with zero attempts
    /// are omitted (rather than reporting 0% with no attempts —
    /// `ForgeReportGenerator` then gracefully scopes Strengths / Growth
    /// Areas to standards the kid has actually engaged).
    public func proficiencies(matching standards: [StandardAlignment]) -> [StandardProficiency] {
        var result: [StandardProficiency] = []
        for standard in standards {
            let relevant = attempts.filter { $0.curriculumStandard == standard.code }
            guard !relevant.isEmpty else { continue }
            let correctCount = relevant.filter(\.wasCorrect).count
            let percentage = (Double(correctCount) / Double(relevant.count)) * 100.0
            result.append(StandardProficiency(
                standard: standard,
                percentage: percentage,
                attemptCount: relevant.count
            ))
        }
        return result
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(attempts)
            defaults.set(data, forKey: Self.userDefaultsKey)
        } catch {
            // Persistence failures shouldn't block the kid's quiz flow.
            // The in-memory log still tracks the session; only the
            // cross-launch persistence is lost.
            DebugLog.error("QuestionAttemptStore.persist failed", error: error)
        }
    }
}
