import Foundation
import ForgeModels
import ForgeReporting

/// Snapshot of every engagement signal that feeds the parent-facing progress
/// report. Pure value type; the caller (typically `AppRootView`) gathers the
/// values from the live services at the moment a parent taps "Progress report"
/// — the snapshot then flows through SettingsView / ProgressReportView without
/// any service-ref plumbing.
///
/// Per `.claude/rules/age-assurance.md` § Portfolio Status: counts only, never
/// PII. `displayName` defaults to "your kid" so the surface stays anonymous
/// even when an avatar `ForgeID.displayName` exists.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Parent & Educator Integration: the report
/// is standards-mapped to NGSS MS-LS1-1 / MS-LS1-2 / MS-LS1-3 / MS-LS2-3 +
/// CCSS RST.6-8 + NHES 1 / 7 (the same tags the bundled question kits carry).
public nonisolated struct ProgressReportSnapshot: Sendable, Equatable {
    public let displayName: String
    public let totalSessions: Int
    public let totalDurationMinutes: Int
    public let activitiesCompleted: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let totalXP: Int
    public let activeDays: Int
    /// Per-standard proficiency rows derived from the
    /// `QuestionAttemptStore`. Empty when no quiz attempts have logged
    /// (e.g., fresh install) — `ForgeReportGenerator.parentConferenceReport`
    /// gracefully skips the Strengths / Growth Areas sections when empty.
    public let standardProficiencies: [StandardProficiency]

    public init(
        displayName: String = "your kid",
        totalSessions: Int,
        totalDurationMinutes: Int,
        activitiesCompleted: Int,
        currentStreak: Int,
        longestStreak: Int,
        totalXP: Int,
        activeDays: Int,
        standardProficiencies: [StandardProficiency] = []
    ) {
        self.displayName = displayName
        self.totalSessions = totalSessions
        self.totalDurationMinutes = totalDurationMinutes
        self.activitiesCompleted = activitiesCompleted
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalXP = totalXP
        self.activeDays = activeDays
        self.standardProficiencies = standardProficiencies
    }
}

/// Stateless service that synthesizes a parent-facing progress report from a
/// `ProgressReportSnapshot`. Wraps `ForgeReporting.ForgeReportGenerator` per
/// `.claude/rules/forgekit.md` § Module Catalog → ForgeReporting.
///
/// **Standards exposure** (Phase 1): the 4 bundled question kits ship with
/// `curriculumStandard` tags spanning NGSS MS-LS1-1 / MS-LS1-2 / MS-LS1-3 /
/// MS-LS2-3 + NHES 1 / 7. The `phase1Standards` list mirrors the bundled
/// kits' tag set so the parent surface stays in sync without a runtime scan.
/// Per-standard proficiency stays empty for Phase 1 (per-question attempt
/// logs land in a follow-up — see `Docs/FEATURE_PLAN.md` § Reporting); the
/// `ForgeReportGenerator.parentConferenceReport(_:)` text gracefully skips
/// the Strengths / Growth Areas sections when proficiencies are empty.
public nonisolated struct ProgressReportService: Sendable {
    /// Phase 1 question-kit standards (kept in sync with the bundled JSON in
    /// `Services/Resources/kit_0*.json`). Standalone constant so the parent
    /// surface can list "Standards covered" without re-scanning the bundle.
    public static let phase1Standards: [StandardAlignment] = [
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS1-1",
            description: "Conduct an investigation to provide evidence that living things are made of cells."
        ),
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS1-2",
            description: "Develop and use a model to describe the function of a cell and its parts."
        ),
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS1-3",
            description: "Use argument to support that the body is a system of interacting subsystems."
        ),
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS2-3",
            description: "Develop a model to describe the cycling of matter and flow of energy among living and nonliving parts of an ecosystem."
        ),
        StandardAlignment(
            standard: .custom,
            code: "NHES 1",
            description: "Comprehend concepts related to health promotion and disease prevention."
        ),
        StandardAlignment(
            standard: .custom,
            code: "NHES 7",
            description: "Demonstrate the ability to practice health-enhancing behaviors."
        ),
    ]

    public init() {}

    /// Synthesizes the `ForgeReporting.StudentReportData` view of the kid's
    /// engagement. Grade defaults to `.seventh` (the middle of the NGSS MS-LS
    /// 6-8 band MicrobeLab targets).
    ///
    /// Per-standard proficiencies derive from the optional
    /// `QuestionAttemptStore` (Services/Engagement/) when wired — its
    /// `proficiencies(matching:)` derivation reads the kid's per-question
    /// answers + maps them onto the phase-1 standards list. Pre-attempt-log,
    /// callers pass `proficiencies: []` (or omit the parameter) so
    /// `ForgeReportGenerator` gracefully skips the Strengths / Growth Areas
    /// sections.
    public func reportData(
        for snapshot: ProgressReportSnapshot,
        grade: GradeLevel = .seventh
    ) -> StudentReportData {
        let averageMinutes: Double = snapshot.totalSessions > 0
            ? Double(snapshot.totalDurationMinutes) / Double(snapshot.totalSessions)
            : 0
        // Average score derives from the snapshot's per-standard proficiencies
        // so the report's summary / recommendations reflect the kid's real
        // accuracy when attempt logs exist. Zero when no attempts logged
        // (avoids implying "0%" mastery on a fresh install).
        let proficiencies = snapshot.standardProficiencies
        let averageScore: Double = proficiencies.isEmpty
            ? 0
            : proficiencies.map(\.percentage).reduce(0, +) / Double(proficiencies.count)
        return StudentReportData(
            studentName: snapshot.displayName,
            gradeLevel: grade,
            totalSessions: snapshot.totalSessions,
            totalDurationMinutes: snapshot.totalDurationMinutes,
            activitiesCompleted: snapshot.activitiesCompleted,
            averageScore: averageScore,
            currentStreak: snapshot.currentStreak,
            totalXP: snapshot.totalXP,
            standardProficiencies: proficiencies,
            period: .allTime,
            generatedAt: .now,
            longestStreak: snapshot.longestStreak,
            averageSessionMinutes: averageMinutes,
            activeDays: snapshot.activeDays
        )
    }

    /// Returns the parent-conference-style report text. ForgeReportGenerator
    /// composes summary + strengths + growth areas + recommendations; when
    /// the snapshot's `standardProficiencies` is empty the strengths/growth
    /// sections are skipped and only summary + recommendations render.
    public func parentReportText(
        for snapshot: ProgressReportSnapshot,
        grade: GradeLevel = .seventh
    ) -> String {
        let data = reportData(for: snapshot, grade: grade)
        return ForgeReportGenerator().parentConferenceReport(data)
    }
}
