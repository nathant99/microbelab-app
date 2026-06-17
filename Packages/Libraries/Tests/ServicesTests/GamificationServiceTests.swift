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

    @Test func phase2SetHasEightAchievements() {
        // Adaptive-immunity quintet (PR #110) + the three per-ecology
        // balance-keeper achievements landed this round (oral / skin /
        // soil). Closes FEATURE_PLAN.md § Phase 2 "Add 8 Phase-2
        // achievements" fully.
        #expect(MicrobeLabAchievements.phase2.count == 8)
    }

    @Test func phase2EcologyBalanceKeepersPresent() {
        let phase2IDs = Set(MicrobeLabAchievements.phase2.map(\.id))
        #expect(phase2IDs.contains(MicrobeLabAchievements.oralBalanceKeeper.id))
        #expect(phase2IDs.contains(MicrobeLabAchievements.skinKindnessChampion.id))
        #expect(phase2IDs.contains(MicrobeLabAchievements.soilDecomposerWhisperer.id))
    }

    @Test func phase2EcologyAchievementsTraumaSafeRegister() {
        // The 3 ecology achievements are positive-tier 80-100 XP rewards.
        // Trauma-informed register: titles + descriptions name care +
        // recognition, never victory or "you finally" framing. Pin a small
        // stoplist so future copy edits don't silently regress.
        let ecology = [
            MicrobeLabAchievements.oralBalanceKeeper,
            MicrobeLabAchievements.skinKindnessChampion,
            MicrobeLabAchievements.soilDecomposerWhisperer
        ]
        let stoplist = ["finally", "at last", "should have", "almost",
                        "failed", "behind", "loser", "fell short",
                        "compared", "better than", "wrong"]
        for definition in ecology {
            let blob = "\(definition.title) \(definition.description)".lowercased()
            for forbidden in stoplist {
                #expect(!blob.contains(forbidden),
                        "Achievement \(definition.id) contains forbidden token '\(forbidden)'")
            }
            // XP value sanity: each is in the 50-150 band like the other
            // Phase 2 achievements; never zero (would silently drop XP).
            #expect(definition.xpValue >= 50)
            #expect(definition.xpValue <= 150)
        }
    }

    @Test func phase2EcologyAchievementsAwardXP() async {
        let service = GamificationService()
        let oral = MicrobeLabAchievements.oralBalanceKeeper
        let skin = MicrobeLabAchievements.skinKindnessChampion
        let soil = MicrobeLabAchievements.soilDecomposerWhisperer
        let earned = service.evaluateAchievements { definition in
            switch definition.id {
            case oral.id, skin.id, soil.id: return true
            default: return false
            }
        }
        #expect(earned.count == 3)
        let expectedXP = oral.xpValue + skin.xpValue + soil.xpValue
        #expect(service.totalXP == expectedXP)
    }

    @Test func allDefinitionsCoversAllPhases() {
        let all = MicrobeLabAchievements.allDefinitions
        let expected = MicrobeLabAchievements.phase1.count
            + MicrobeLabAchievements.phase2.count
            + MicrobeLabAchievements.phase3.count
        #expect(all.count == expected)
        // Spot-check all three phases land in the aggregate.
        #expect(all.contains(where: { $0.id == MicrobeLabAchievements.firstZoom.id }))
        #expect(all.contains(where: { $0.id == MicrobeLabAchievements.firstShapeMatch.id }))
        #expect(all.contains(where: { $0.id == MicrobeLabAchievements.librarianOfShapes.id }))
        #expect(all.contains(where: { $0.id == MicrobeLabAchievements.handwashHero.id }))
        #expect(all.contains(where: { $0.id == MicrobeLabAchievements.outbreakHelper.id }))
    }

    @Test func phase2IDsAreUnique() {
        let ids = MicrobeLabAchievements.phase2.map(\.id)
        #expect(Set(ids).count == ids.count, "Phase-2 achievement IDs must be unique")
    }

    @Test func phase3SetHasFourAchievements() {
        #expect(MicrobeLabAchievements.phase3.count == 4)
    }

    @Test func phase3IDsAreUnique() {
        let ids = MicrobeLabAchievements.phase3.map(\.id)
        #expect(Set(ids).count == ids.count, "Phase-3 achievement IDs must be unique")
    }

    @Test func phase3XPBandHonored() {
        // Phase-3 achievements stay in the 60-120 XP band, matching the
        // Phase-2 spread. Avoid epic-tier inflation as we extend the set.
        for achievement in MicrobeLabAchievements.phase3 {
            #expect(achievement.xpValue >= 60,
                    "\(achievement.id) below the Phase-3 XP floor (60)")
            #expect(achievement.xpValue <= 120,
                    "\(achievement.id) above the Phase-3 XP ceiling (120)")
        }
    }

    @Test func phase3AchievementsTraumaSafeRegister() {
        // Phase-3 disease-story achievements ship under the SAMHSA register
        // per ADR-016 + .claude/rules/trauma-informed-content.md. The titles +
        // descriptions must avoid: warfare lexicon (fight / attack / defeat /
        // battle / weapon / kill / war / enemy), shame lexicon (failure /
        // should / must / behind / almost / fell short), threat lexicon
        // (scary / germ / panic / horror / danger).
        let stoplist = [
            // Warfare
            "fight", "attack", "defeat", "battle", "weapon", "kill",
            " war", "enemy", "soldier", "warrior",
            // Shame
            "failure", "should ", "must ", "behind", "almost", "fell short",
            // Threat
            "scary", "germ", "panic", "horror", "danger",
        ]
        for achievement in MicrobeLabAchievements.phase3 {
            let combined = (achievement.title + " " + achievement.description).lowercased()
            for word in stoplist {
                #expect(!combined.contains(word),
                        "Phase-3 achievement '\(achievement.id)' must not surface '\(word.trimmingCharacters(in: .whitespaces))' (trauma-safe register).")
            }
        }
    }

    @Test func phase3AchievementsAwardXP() async {
        let service = GamificationService()
        let hero = MicrobeLabAchievements.handwashHero
        let primer = MicrobeLabAchievements.vaccinePrimer
        let earned = service.evaluateAchievements { definition in
            switch definition.id {
            case hero.id, primer.id: return true
            default: return false
            }
        }
        #expect(earned.count == 2)
        let expectedXP = hero.xpValue + primer.xpValue
        #expect(service.totalXP == expectedXP)
    }

    @Test func allDefinitionsHaveUniqueIDs() {
        // Hard collision check: id collisions silently coalesce
        // achievements in the AchievementEngine evaluation path. Every
        // shipped definition must carry a distinct id.
        let ids = MicrobeLabAchievements.allDefinitions.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func phase2AchievementsAwardXP() async {
        let service = GamificationService()
        let firstMatch = MicrobeLabAchievements.firstShapeMatch
        let memoryAwakened = MicrobeLabAchievements.memoryAwakened
        let earned = service.evaluateAchievements { definition in
            switch definition.id {
            case firstMatch.id, memoryAwakened.id: return true
            default: return false
            }
        }
        #expect(earned.count == 2)
        let expectedXP = firstMatch.xpValue + memoryAwakened.xpValue
        #expect(service.totalXP == expectedXP)
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
