import Testing
import Foundation
import ForgeModels
@testable import Services

@Suite("ProgressReportService") struct ProgressReportServiceTests {

    @Test("phase1Standards covers all bundled kit tags")
    func phase1StandardsCoverage() {
        let codes = Set(ProgressReportService.phase1Standards.map(\.code))
        // The 4 bundled question kits ship `curriculumStandard` tags spanning
        // NGSS MS-LS1-1/2/3 + MS-LS2-3 + NHES 1 + 7. Tests pin that
        // ProgressReportService stays in sync with the bundled JSON; if a kit
        // adds a tag the standards list must follow in the same PR.
        #expect(codes.contains("MS-LS1-1"))
        #expect(codes.contains("MS-LS1-2"))
        #expect(codes.contains("MS-LS1-3"))
        #expect(codes.contains("MS-LS2-3"))
        #expect(codes.contains("NHES 1"))
        #expect(codes.contains("NHES 7"))
    }

    @Test("reportData maps snapshot fields verbatim")
    func reportDataPreservesEngagement() {
        let snapshot = ProgressReportSnapshot(
            displayName: "Test Explorer",
            totalSessions: 12,
            totalDurationMinutes: 72,
            activitiesCompleted: 4,
            currentStreak: 3,
            longestStreak: 9,
            totalXP: 240,
            activeDays: 6
        )
        let data = ProgressReportService().reportData(for: snapshot)
        #expect(data.studentName == "Test Explorer")
        #expect(data.totalSessions == 12)
        #expect(data.totalDurationMinutes == 72)
        #expect(data.activitiesCompleted == 4)
        #expect(data.currentStreak == 3)
        #expect(data.longestStreak == 9)
        #expect(data.totalXP == 240)
        #expect(data.activeDays == 6)
        #expect(data.gradeLevel == .seventh)
    }

    @Test("reportData averageSessionMinutes computes from total / count")
    func averageSessionMinutes() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 4,
            totalDurationMinutes: 60,
            activitiesCompleted: 0,
            currentStreak: 0,
            longestStreak: 0,
            totalXP: 0,
            activeDays: 0
        )
        let data = ProgressReportService().reportData(for: snapshot)
        #expect(data.averageSessionMinutes == 15.0)
    }

    @Test("reportData averageSessionMinutes is zero when no sessions")
    func averageSessionMinutesZeroSessions() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 0,
            totalDurationMinutes: 0,
            activitiesCompleted: 0,
            currentStreak: 0,
            longestStreak: 0,
            totalXP: 0,
            activeDays: 0
        )
        let data = ProgressReportService().reportData(for: snapshot)
        #expect(data.averageSessionMinutes == 0.0)
    }

    @Test("parentReportText never includes PII placeholders")
    func parentReportTextAnonymous() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 5,
            totalDurationMinutes: 30,
            activitiesCompleted: 2,
            currentStreak: 1,
            longestStreak: 1,
            totalXP: 50,
            activeDays: 2
        )
        let text = ProgressReportService().parentReportText(for: snapshot)
        // Default displayName is "your kid" — anonymous by design.
        #expect(text.contains("your kid"))
        // Sanity: ForgeReportGenerator's canonical Summary header lands.
        #expect(text.contains("Summary"))
    }

    @Test("parentReportText recommends frequent practice when sessions are low")
    func parentReportTextLowSessionsHint() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 1,
            totalDurationMinutes: 5,
            activitiesCompleted: 0,
            currentStreak: 0,
            longestStreak: 0,
            totalXP: 5,
            activeDays: 1
        )
        let text = ProgressReportService().parentReportText(for: snapshot)
        // ForgeReportGenerator surfaces "Encourage more frequent practice
        // sessions" when totalSessions < 5; pin that the recommendation
        // text flows through unmodified so the parent surface stays
        // consistent with the canonical ForgeKit copy.
        #expect(text.contains("Encourage more frequent practice"))
    }

    @Test("parentReportText skips standards sections when empty")
    func parentReportTextSkipsEmptyStandards() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 8,
            totalDurationMinutes: 40,
            activitiesCompleted: 3,
            currentStreak: 4,
            longestStreak: 6,
            totalXP: 150,
            activeDays: 4
        )
        let text = ProgressReportService().parentReportText(for: snapshot)
        // With empty standardProficiencies, the strengths/growth sections do
        // not appear in the canonical report text.
        #expect(!text.contains("Strengths"))
        #expect(!text.contains("Growth Areas"))
    }

    @Test("phase1Standards entries carry NGSS framework code where expected")
    func phase1StandardsFrameworkAssignment() {
        let lookup = Dictionary(uniqueKeysWithValues: ProgressReportService.phase1Standards.map { ($0.code, $0.standard) })
        #expect(lookup["MS-LS1-1"] == .ngss)
        #expect(lookup["MS-LS1-2"] == .ngss)
        #expect(lookup["MS-LS1-3"] == .ngss)
        #expect(lookup["MS-LS2-3"] == .ngss)
        // NHES isn't one of the canonical CurriculumStandard enum cases, so
        // the service maps it through .custom — pin that choice so a future
        // ForgeKit revision adding NHES doesn't silently change the
        // classification surface.
        #expect(lookup["NHES 1"] == .custom)
        #expect(lookup["NHES 7"] == .custom)
    }

    // MARK: - Phase 2-4 standards coverage

    @Test("phase2Standards covers the new MS-LS2-2 ecology-interactions standard")
    func phase2StandardsCoverage() {
        let codes = Set(ProgressReportService.phase2Standards.map(\.code))
        // Phase 2 introduces MS-LS2-2 (interactions in ecosystems) via the 3
        // microbiome ecology kits (oral / skin / soil). MS-LS1-3 is re-used
        // from Phase 1 by the adaptive-immunity kit.
        #expect(codes.contains("MS-LS2-2"))
        #expect(codes.contains("MS-LS1-3"))
    }

    @Test("phase3Standards anchors on the immune-subsystem code")
    func phase3StandardsCoverage() {
        let codes = Set(ProgressReportService.phase3Standards.map(\.code))
        // All 4 Phase 3 placeholder kits anchor on MS-LS1-3 (immune
        // subsystem) per their curriculumStandard JSON tags.
        #expect(codes.contains("MS-LS1-3"))
    }

    @Test("phase4Standards covers both extremophile-ecosystem and synthesis-cells codes")
    func phase4StandardsCoverage() {
        let codes = Set(ProgressReportService.phase4Standards.map(\.code))
        // Phase 4 kits anchor on MS-LS2-3 (extremophiles + global) +
        // MS-LS1-1 (research + synthesis arc) per their curriculumStandard
        // JSON tags from PR #159.
        #expect(codes.contains("MS-LS2-3"))
        #expect(codes.contains("MS-LS1-1"))
    }

    @Test("allShippedStandards deduplicates standards across phases by code")
    func allShippedStandardsDeduplicates() {
        let standards = ProgressReportService.allShippedStandards
        let codes = standards.map(\.code)
        // Deduplication invariant: every code appears exactly once even
        // though phase1/phase2/phase4 all reference MS-LS1-3 or MS-LS2-3.
        #expect(Set(codes).count == codes.count,
                "allShippedStandards must dedupe by code; duplicates found: \(codes)")
        // Sanity: at minimum the Phase 1 codes are present.
        let codeSet = Set(codes)
        #expect(codeSet.contains("MS-LS1-1"))
        #expect(codeSet.contains("MS-LS1-2"))
        #expect(codeSet.contains("MS-LS1-3"))
        #expect(codeSet.contains("MS-LS2-3"))
        #expect(codeSet.contains("NHES 1"))
        #expect(codeSet.contains("NHES 7"))
        // Phase 2's new ecology standard surfaces in the union.
        #expect(codeSet.contains("MS-LS2-2"))
    }

    @Test("allShippedStandards order preserves Phase 1 priority")
    func allShippedStandardsOrderingPreservesPhase1First() {
        let codes = ProgressReportService.allShippedStandards.map(\.code)
        // Phase 1 codes appear first in canonical order. Stable order is
        // load-bearing for the parent surface's "Standards covered" list so
        // the most-foundational codes lead the list.
        let phase1Codes = ProgressReportService.phase1Standards.map(\.code)
        let prefix = Array(codes.prefix(phase1Codes.count))
        #expect(prefix == phase1Codes,
                "First phase1Standards.count codes in allShippedStandards must match phase1 order; got \(prefix)")
    }
}
