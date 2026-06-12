import Foundation
import Testing
@testable import Services

@Suite("GamificationService")
@MainActor
struct GamificationServiceTests {
    @Test func awardXPAccumulates() {
        let service = GamificationService()
        service.awardXP(40, reason: "test")
        service.awardXP(60, reason: "test")
        #expect(service.totalXP == 100)
    }

    @Test func awardingNegativeOrZeroIsNoOp() {
        let service = GamificationService()
        service.awardXP(0, reason: "noop")
        service.awardXP(-50, reason: "underflow")
        #expect(service.totalXP == 0)
    }

    @Test func evaluateGrantsNewAchievementAndXP() {
        let service = GamificationService()
        let firstQuiz = MicrobeLabAchievements.firstQuiz
        let earned = service.evaluateAchievements { definition in
            definition.id == firstQuiz.id
        }
        #expect(earned.contains { $0.id == firstQuiz.id })
        #expect(service.earnedAchievementSlugs.contains(firstQuiz.id))
        #expect(service.totalXP == firstQuiz.xpValue)
    }

    @Test func evaluateSkipsAlreadyEarned() {
        let service = GamificationService()
        let firstQuiz = MicrobeLabAchievements.firstQuiz
        _ = service.evaluateAchievements { $0.id == firstQuiz.id }
        let xpAfterFirst = service.totalXP
        let earned = service.evaluateAchievements { $0.id == firstQuiz.id }
        #expect(earned.isEmpty)
        #expect(service.totalXP == xpAfterFirst, "Re-evaluating must not double-award XP")
    }

    @Test func phase1SetHasTenAchievements() {
        #expect(MicrobeLabAchievements.phase1.count == 10)
    }

    @Test func hydratedFromStreakStoreReadsPersistedCounters() {
        // swiftlint:disable:next force_unwrapping
        let defaults = UserDefaults(suiteName: "\(#file).hydration")!
        defaults.removePersistentDomain(forName: "\(#file).hydration")
        let store = StreakStore(defaults: defaults, keyPrefix: "hydration")
        store.save(currentStreak: 9, longestStreak: 14, availableFreezes: 1, recordedAt: .now)

        let service = GamificationService.hydrated(from: store)
        #expect(service.currentStreak == 9)
        #expect(service.longestStreak == 14)
    }

    @Test func recordSessionPersistsToInjectedStore() async {
        // swiftlint:disable:next force_unwrapping
        let defaults = UserDefaults(suiteName: "\(#file).persist")!
        defaults.removePersistentDomain(forName: "\(#file).persist")
        let store = StreakStore(defaults: defaults, keyPrefix: "persist")

        let service = GamificationService.hydrated(from: store)
        let now = Date.now
        await service.recordSession(date: now)

        // First-ever recordSession bumps current to 1; the store reads back
        // the same value because the service flushes after the async update.
        #expect(store.currentStreak == 1)
        #expect(store.lastRecordedAt != nil)
    }
}
