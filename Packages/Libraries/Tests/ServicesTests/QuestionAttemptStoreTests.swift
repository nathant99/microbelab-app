import Foundation
import Testing
@testable import Services
@testable import Models
import ForgeModels
import ForgeReporting

@Suite("QuestionAttemptStore")
@MainActor
struct QuestionAttemptStoreTests {
    private static func makeIsolatedDefaults(_ suite: String = #function) -> UserDefaults {
        let name = "QuestionAttemptStoreTests-\(suite)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// Canonical fixture — one question tagged to NGSS MS-LS1-1.
    private static func sampleQuestion(standard: String? = "MS-LS1-1") -> Question {
        Question(
            id: UUID(),
            prompt: "What's a microbe?",
            choices: ["a", "b", "c"],
            correctIndex: 0,
            explanation: "Tiny living thing.",
            curriculumStandard: standard
        )
    }

    @Test func freshStoreIsEmpty() {
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        #expect(store.attempts.isEmpty)
    }

    @Test func recordAttemptAppendsRecord() {
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        let q = Self.sampleQuestion()
        store.recordAttempt(question: q, kitSlug: "kit_01", wasCorrect: true)
        #expect(store.attempts.count == 1)
        #expect(store.attempts[0].questionID == q.id)
        #expect(store.attempts[0].kitSlug == "kit_01")
        #expect(store.attempts[0].curriculumStandard == "MS-LS1-1")
        #expect(store.attempts[0].wasCorrect == true)
    }

    @Test func recordAttemptPersistsAcrossInstances() {
        let defaults = Self.makeIsolatedDefaults()
        let first = QuestionAttemptStore(defaults: defaults)
        first.recordAttempt(question: Self.sampleQuestion(), kitSlug: "kit_01", wasCorrect: true)
        first.recordAttempt(question: Self.sampleQuestion(), kitSlug: "kit_02", wasCorrect: false)

        let second = QuestionAttemptStore(defaults: defaults)
        #expect(second.attempts.count == 2)
    }

    @Test func capEvictsOldestAttempt() {
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults(), maxAttempts: 3)
        for i in 0..<5 {
            let q = Self.sampleQuestion(standard: "MS-LS1-\(i)")
            store.recordAttempt(question: q, kitSlug: "kit_0\(i)", wasCorrect: i.isMultiple(of: 2))
        }
        #expect(store.attempts.count == 3)
        // FIFO eviction — the two oldest dropped.
        #expect(store.attempts[0].kitSlug == "kit_02")
        #expect(store.attempts[2].kitSlug == "kit_04")
    }

    @Test func proficienciesScopeToStandardsWithAttempts() {
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        // 3 attempts on MS-LS1-1 (2 correct), 0 on MS-LS1-2, 1 on MS-LS1-3.
        let q1 = Self.sampleQuestion(standard: "MS-LS1-1")
        let q3 = Self.sampleQuestion(standard: "MS-LS1-3")
        store.recordAttempt(question: q1, kitSlug: "kit_01", wasCorrect: true)
        store.recordAttempt(question: q1, kitSlug: "kit_01", wasCorrect: true)
        store.recordAttempt(question: q1, kitSlug: "kit_01", wasCorrect: false)
        store.recordAttempt(question: q3, kitSlug: "kit_03", wasCorrect: false)

        let proficiencies = store.proficiencies(matching: ProgressReportService.phase1Standards)
        // MS-LS1-1 should appear with 2/3 = 66.67%, MS-LS1-3 with 0/1 = 0%.
        // MS-LS1-2 and MS-LS2-3 omitted (no attempts).
        let codes = Set(proficiencies.map(\.standard.code))
        #expect(codes.contains("MS-LS1-1"))
        #expect(codes.contains("MS-LS1-3"))
        #expect(!codes.contains("MS-LS1-2"))
        #expect(!codes.contains("MS-LS2-3"))

        if let lsa = proficiencies.first(where: { $0.standard.code == "MS-LS1-1" }) {
            #expect(lsa.attemptCount == 3)
            #expect(lsa.percentage > 66.0 && lsa.percentage < 67.0)
        } else {
            Issue.record("MS-LS1-1 proficiency missing")
        }
    }

    @Test func proficienciesEmptyOnFreshInstall() {
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        let proficiencies = store.proficiencies(matching: ProgressReportService.phase1Standards)
        #expect(proficiencies.isEmpty)
    }

    @Test func untaggedQuestionStillLogsButSkipsProficiency() {
        // Authored content without a curriculumStandard tag — the attempt
        // log still counts the answer (per-kit reporting needs the row)
        // but it's omitted from proficiency derivation since no standard
        // anchors it.
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        let untagged = Self.sampleQuestion(standard: nil)
        store.recordAttempt(question: untagged, kitSlug: "kit_99", wasCorrect: true)
        #expect(store.attempts.count == 1)
        let proficiencies = store.proficiencies(matching: ProgressReportService.phase1Standards)
        #expect(proficiencies.isEmpty)
    }

    @Test func clearForTestingWipesState() {
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        store.recordAttempt(question: Self.sampleQuestion(), kitSlug: "kit_01", wasCorrect: true)
        store.clearForTesting()
        #expect(store.attempts.isEmpty)
    }

    @Test func userDefaultsKeyIsStable() {
        // Renaming the persistence key without a migration orphans the
        // kid's prior attempt log. Pin the canonical value.
        #expect(QuestionAttemptStore.userDefaultsKey == "com.microbelab.quiz.attempts")
        #expect(QuestionAttemptStore.defaultMaxAttempts == 500)
    }

    @Test func proficienciesFeedReportServiceAverageScore() {
        // Per-standard averages flow through ProgressReportService — the
        // service derives the report's averageScore from the proficiency
        // mean. This pins the contract for the parent-facing summary.
        let store = QuestionAttemptStore(defaults: Self.makeIsolatedDefaults())
        let q1 = Self.sampleQuestion(standard: "MS-LS1-1")
        let q2 = Self.sampleQuestion(standard: "MS-LS1-2")
        // 100% on MS-LS1-1, 0% on MS-LS1-2 → mean = 50%.
        store.recordAttempt(question: q1, kitSlug: "kit_01", wasCorrect: true)
        store.recordAttempt(question: q1, kitSlug: "kit_01", wasCorrect: true)
        store.recordAttempt(question: q2, kitSlug: "kit_02", wasCorrect: false)

        let proficiencies = store.proficiencies(matching: ProgressReportService.phase1Standards)
        let snapshot = ProgressReportSnapshot(
            totalSessions: 1,
            totalDurationMinutes: 5,
            activitiesCompleted: 1,
            currentStreak: 1,
            longestStreak: 1,
            totalXP: 50,
            activeDays: 1,
            standardProficiencies: proficiencies
        )
        let report = ProgressReportService().reportData(for: snapshot)
        // Two standards average to ~50%.
        #expect(report.averageScore > 49.0 && report.averageScore < 51.0)
        #expect(report.standardProficiencies.count == 2)
    }
}
