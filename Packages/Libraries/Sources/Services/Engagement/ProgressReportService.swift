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
/// **Standards exposure** (Phases 1-4): each phase's `phaseNStandards`
/// constant mirrors the standards tagged by that phase's bundled question
/// kits. `allShippedStandards` returns the deduplicated union (by `code`)
/// of every phase shipped to date so the parent surface stays in sync
/// without a runtime scan. Per-standard proficiency stays empty until the
/// kid has answered a tagged question (see `QuestionAttemptStore`); the
/// `ForgeReportGenerator.parentConferenceReport(_:)` text gracefully skips
/// the Strengths / Growth Areas sections when proficiencies are empty.
public nonisolated struct ProgressReportService: Sendable {
    /// Phase 1 question-kit standards (kept in sync with the bundled JSON in
    /// `Services/Resources/kit_0[1-4]*.json`). Standalone constant so the
    /// parent surface can list "Standards covered" without re-scanning the
    /// bundle.
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

    /// Phase 2 question-kit standards (kits 05 adaptive immunity + 06 oral
    /// + 07 skin + 08 soil microbiomes). New canonical entry: MS-LS2-2
    /// (interactions in ecosystems) — surfaced by the 3 microbiome ecology
    /// kits per their `curriculumStandard` tags. MS-LS1-3 is also re-used
    /// from Phase 1 (the adaptive-immunity kit anchors on the immune-
    /// subsystem standard).
    public static let phase2Standards: [StandardAlignment] = [
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS1-3",
            description: "Use argument to support that the body is a system of interacting subsystems."
        ),
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS2-2",
            description: "Construct an explanation that predicts patterns of interactions among organisms across multiple ecosystems."
        ),
    ]

    /// Phase 3 question-kit standards (kits 09 vaccines + 10 herd immunity +
    /// 11 hygiene + 12 public health). All four kits anchor on MS-LS1-3
    /// (immune subsystem) per their `curriculumStandard` JSON tags. Real
    /// prose remains reviewer-blocked per ADR-016; the standards list ships
    /// so the parent surface can describe what the kit set covers
    /// curricularly without committing to reviewer-blocked prose.
    public static let phase3Standards: [StandardAlignment] = [
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS1-3",
            description: "Use argument to support that the body is a system of interacting subsystems."
        ),
    ]

    /// Phase 4 question-kit standards (kits 13 extremophiles + 14 global
    /// microbiome + 15 microbiome research + 16 synthesis). Kits 13 + 14
    /// anchor on MS-LS2-3 (matter + energy cycling across ecosystems —
    /// extremophile habitats + global tour); kits 15 + 16 anchor on
    /// MS-LS1-1 (the foundational cells-as-living-things standard, used as
    /// the synthesis-arc bridge). Real prose remains reviewer-blocked.
    public static let phase4Standards: [StandardAlignment] = [
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS1-1",
            description: "Conduct an investigation to provide evidence that living things are made of cells."
        ),
        StandardAlignment(
            standard: .ngss,
            code: "MS-LS2-3",
            description: "Develop a model to describe the cycling of matter and flow of energy among living and nonliving parts of an ecosystem."
        ),
    ]

    /// Deduplicated union (by `code`) of every standard covered by the
    /// shipped question kits across all four phases. Stable order: Phase 1
    /// standards first, then Phase 2 additions, then Phase 3 + Phase 4
    /// additions. The parent surface uses this list to render the
    /// "Standards covered" affordance without re-scanning the bundle.
    public static var allShippedStandards: [StandardAlignment] {
        var seenCodes = Set<String>()
        var result: [StandardAlignment] = []
        for alignment in phase1Standards + phase2Standards + phase3Standards + phase4Standards {
            guard !seenCodes.contains(alignment.code) else { continue }
            seenCodes.insert(alignment.code)
            result.append(alignment)
        }
        return result
    }

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
