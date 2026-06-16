import Foundation
import Testing
import ForgeProgression
@testable import Services

@Suite("ProgressionService")
@MainActor
struct ProgressionServiceTests {

    // Each test uses a unique persistenceKey so UserDefaults state doesn't
    // leak between tests. The service's `resetForTest()` clears state at
    // setup; the per-test key ensures isolation even when state lingers.
    private func makeService(testTag: String = #function) -> ProgressionService {
        let service = ProgressionService(persistenceKey: "MicrobeLabProgressionTest-\(testTag)")
        service.resetForTest()
        return service
    }

    @Test func canonicalGatesAreRegistered() {
        let gates = ProgressionService.canonicalGates()
        let ids = Set(gates.map(\.id))
        #expect(ids == [
            ProgressionService.diseaseStoryImmuneGateID,
            ProgressionService.diseaseStoryMicrobiomeGateID,
            ProgressionService.globalMicrobiomeTourGateID,
        ])
    }

    @Test func sessionCountStartsAtZero() {
        let service = makeService()
        #expect(service.sessionCount == 0)
    }

    @Test func recordSessionIncrementsCount() {
        let service = makeService()
        let day1 = Date(timeIntervalSince1970: 0)
        #expect(service.recordSession(date: day1) == true)
        #expect(service.sessionCount == 1)
    }

    @Test func sameDayDeduplicated() {
        let service = makeService()
        let day1 = Date(timeIntervalSince1970: 0)
        let day1Later = Date(timeIntervalSince1970: 60 * 60 * 12)
        _ = service.recordSession(date: day1)
        #expect(service.recordSession(date: day1Later) == false,
                "second call same calendar day must NOT increment")
        #expect(service.sessionCount == 1)
    }

    @Test func differentDaysIncrement() {
        let service = makeService()
        let day1 = Date(timeIntervalSince1970: 0)
        let day2 = Date(timeIntervalSince1970: 60 * 60 * 24)
        _ = service.recordSession(date: day1)
        _ = service.recordSession(date: day2)
        #expect(service.sessionCount == 2)
    }

    @Test func diseaseStoryImmuneLockedAtZero() {
        let service = makeService()
        #expect(service.isUnlocked(ProgressionService.diseaseStoryImmuneGateID) == false)
    }

    @Test func diseaseStoryImmuneNeedsBothSessionsAndImmuneRuns() {
        let service = makeService()
        // Hit session threshold (5) but no immune runs → still locked.
        for day in 0..<5 {
            _ = service.recordSession(date: Date(timeIntervalSince1970: TimeInterval(day) * 86_400))
        }
        #expect(service.isUnlocked(ProgressionService.diseaseStoryImmuneGateID) == false,
                "5 sessions alone must NOT unlock; secondary immune-runs criterion is required")

        // Hit immune-runs threshold (3) → unlocks.
        for _ in 0..<3 {
            service.recordImmuneRunCompleted()
        }
        #expect(service.isUnlocked(ProgressionService.diseaseStoryImmuneGateID) == true)
    }

    @Test func diseaseStoryMicrobiomeNeedsBothSessionsAndSceneVisits() {
        let service = makeService()
        for day in 0..<5 {
            _ = service.recordSession(date: Date(timeIntervalSince1970: TimeInterval(day) * 86_400))
        }
        #expect(service.isUnlocked(ProgressionService.diseaseStoryMicrobiomeGateID) == false)
        for _ in 0..<5 {
            service.recordMicrobiomeSceneVisited()
        }
        #expect(service.isUnlocked(ProgressionService.diseaseStoryMicrobiomeGateID) == true)
    }

    @Test func globalTourNeedsEightSessionsAndAllFourEcologies() {
        let service = makeService()
        for day in 0..<8 {
            _ = service.recordSession(date: Date(timeIntervalSince1970: TimeInterval(day) * 86_400))
        }
        // Only 3 distinct ecologies → still locked.
        service.recordEcologyScenesVisited(distinctCount: 3)
        #expect(service.isUnlocked(ProgressionService.globalMicrobiomeTourGateID) == false)
        // Bump to 4 distinct → unlocks.
        service.recordEcologyScenesVisited(distinctCount: 4)
        #expect(service.isUnlocked(ProgressionService.globalMicrobiomeTourGateID) == true)
    }

    @Test func unlockHintReturnsCopyOnlyWhenLocked() {
        let service = makeService()
        // Locked → returns hint copy.
        let hint = service.unlockHint(for: ProgressionService.diseaseStoryImmuneGateID)
        #expect(hint != nil)
        #expect(hint?.contains("5 different days") == true)
        #expect(hint?.contains("3 immune runs") == true)
        // Unlock the gate → hint is nil.
        for day in 0..<5 {
            _ = service.recordSession(date: Date(timeIntervalSince1970: TimeInterval(day) * 86_400))
        }
        for _ in 0..<3 {
            service.recordImmuneRunCompleted()
        }
        #expect(service.unlockHint(for: ProgressionService.diseaseStoryImmuneGateID) == nil)
    }

    @Test func unlockHintTraumaInformedRegisterPinned() {
        // Every unlock-hint string MUST be free of the trauma-informed
        // register stoplist (per .claude/rules/distributed-narrative.md §
        // Chapter content register stoplist + trauma-informed-content.md).
        // The Phase 3 / Phase 4 hint copy lives ON SURFACE the kid sees;
        // the same register discipline applies.
        let stoplist = ["failed", "fail", "behind", "lose", "loser", "not yet ready",
                        "must", "should", "punish", "lock you out", "wrong"]
        for gate in ProgressionService.canonicalGates() {
            let hint = gate.unlockHint
            for token in stoplist {
                #expect(!hint.localizedCaseInsensitiveContains(token),
                        "ContentGate \(gate.id) hint must NOT contain '\(token)' — register stoplist violation. Hint: \(hint)")
            }
        }
    }

    @Test func debugBypassUnlocksEveryGate() {
        let service = makeService()
        #expect(service.isUnlocked(ProgressionService.diseaseStoryImmuneGateID) == false)
        service.debugUnlockAllGates()
        #expect(service.isUnlocked(ProgressionService.diseaseStoryImmuneGateID) == true)
        #expect(service.isUnlocked(ProgressionService.diseaseStoryMicrobiomeGateID) == true)
        #expect(service.isUnlocked(ProgressionService.globalMicrobiomeTourGateID) == true)
        service.debugRestoreGateEvaluation()
        #expect(service.isUnlocked(ProgressionService.diseaseStoryImmuneGateID) == false)
    }

    @Test func unlockProgressShowsPerCriterionState() {
        let service = makeService()
        let progress = service.unlockProgress(for: ProgressionService.diseaseStoryImmuneGateID)
        // First entry is always sessions; subsequent entries are secondary criteria.
        #expect(progress.count == 2)
        #expect(progress[0].requiredValue == 5)
        #expect(progress[0].currentValue == 0)
        #expect(progress[1].requiredValue == 3)
        #expect(progress[1].currentValue == 0)
        // Record 2 sessions + 1 immune run → progress updates.
        _ = service.recordSession(date: Date(timeIntervalSince1970: 0))
        _ = service.recordSession(date: Date(timeIntervalSince1970: 86_400))
        service.recordImmuneRunCompleted()
        let updated = service.unlockProgress(for: ProgressionService.diseaseStoryImmuneGateID)
        #expect(updated[0].currentValue == 2)
        #expect(updated[1].currentValue == 1)
    }

    @Test func metricRecordingIsCumulativeNotReplacing() {
        let service = makeService()
        service.recordImmuneRunCompleted()
        service.recordImmuneRunCompleted()
        service.recordImmuneRunCompleted()
        #expect(service.metricValue(for: ProgressionService.immuneRunsMetricKey) == 3)
    }

    @Test func ecologyDistinctCountClampsNegativeToZero() {
        let service = makeService()
        service.recordEcologyScenesVisited(distinctCount: -3)
        #expect(service.metricValue(for: ProgressionService.ecologyScenesVisitedMetricKey) == 0)
    }
}
