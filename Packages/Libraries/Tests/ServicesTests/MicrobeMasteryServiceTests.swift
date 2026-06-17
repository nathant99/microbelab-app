import Testing
import Foundation
import Models
@testable import Services

@Suite("MicrobeMasteryService (ForgeGamification FSRS-6 wrapper)")
@MainActor
struct MicrobeMasteryServiceTests {

    private func makeMicrobe(
        slug: String,
        displayName: String,
        environment: GutSlot = .colon,
        firstKit: Int = 1
    ) -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: slug,
            displayName: displayName,
            kingdom: .bacteria,
            role: .beneficial,
            preferredEnvironment: environment,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: 0),
            catchphrase: "Hi",
            factCard: "Fact",
            firstKit: firstKit
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MicrobeMasteryServiceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Prerequisite topology

    @Test("buildPrerequisites — flat catalog has zero prerequisites (all kit-01)")
    func buildPrerequisites_flatCatalog_noPrereqs() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", firstKit: 1)
        let map = MicrobeMasteryService.buildPrerequisites(from: [lacto, bifido])
        #expect(map["lacto"]?.isEmpty == true)
        #expect(map["bifido"]?.isEmpty == true)
    }

    @Test("buildPrerequisites — same-habitat earlier-kit microbe is a prerequisite")
    func buildPrerequisites_sameHabitat_earlierKit_isPrereq() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon, firstKit: 1)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", environment: .colon, firstKit: 3)
        let map = MicrobeMasteryService.buildPrerequisites(from: [lacto, bifido])
        #expect(map["bifido"] == ["lacto"])
        #expect(map["lacto"]?.isEmpty == true)
    }

    @Test("buildPrerequisites — different habitat earlier-kit microbe is NOT a prerequisite")
    func buildPrerequisites_differentHabitat_notPrereq() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", environment: .colon, firstKit: 1)
        let sebu = makeMicrobe(slug: "sebu", displayName: "Sebu", environment: .skin, firstKit: 3)
        let map = MicrobeMasteryService.buildPrerequisites(from: [lacto, sebu])
        #expect(map["sebu"]?.isEmpty == true)
    }

    @Test("init — empty catalog yields a constructable service")
    func init_emptyCatalog() {
        let svc = MicrobeMasteryService(catalog: [], defaults: makeDefaults())
        #expect(svc.habitatPrerequisites.isEmpty)
        #expect(svc.records.isEmpty)
        #expect(svc.recommendedNextMicrobe(among: ["lacto"]) == nil)
    }

    // MARK: - Encounter recording

    @Test("recordEncounter — appends a record for the slug")
    func recordEncounter_appendsRecord() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults())
        #expect(svc.records["lacto"] == nil)
        svc.recordEncounter(slug: "lacto", wasCorrect: true)
        #expect(svc.records["lacto"]?.attemptCount == 1)
        #expect(svc.records["lacto"]?.recentOutcomes == [true])
    }

    @Test("recordEncounter — unknown slug is a no-op")
    func recordEncounter_unknownSlug_noop() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults())
        svc.recordEncounter(slug: "ghost-microbe-not-in-catalog", wasCorrect: true)
        #expect(svc.records.isEmpty)
    }

    @Test("recordEncounter — multiple encounters accumulate attempts + outcomes")
    func recordEncounter_multipleAccumulate() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults())
        for _ in 0..<5 {
            svc.recordEncounter(slug: "lacto", wasCorrect: true)
        }
        #expect(svc.records["lacto"]?.attemptCount == 5)
        #expect(svc.records["lacto"]?.recentOutcomes == [true, true, true, true, true])
    }

    @Test("recordEncounter — rolling window FIFO-evicts past capacity")
    func recordEncounter_windowFIFOEviction() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults(), recentWindowSize: 3)
        svc.recordEncounter(slug: "lacto", wasCorrect: false)
        svc.recordEncounter(slug: "lacto", wasCorrect: true)
        svc.recordEncounter(slug: "lacto", wasCorrect: true)
        svc.recordEncounter(slug: "lacto", wasCorrect: true)
        // Oldest .false evicted; window now [true, true, true]
        #expect(svc.records["lacto"]?.recentOutcomes == [true, true, true])
        #expect(svc.records["lacto"]?.attemptCount == 4)
    }

    @Test("masteryScore — zero for an unseen microbe")
    func masteryScore_unseen_isZero() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults())
        #expect(svc.masteryScore(forSlug: "lacto") == 0)
    }

    @Test("masteryScore — positive after repeated correct encounters")
    func masteryScore_positiveAfterCorrects() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults())
        for _ in 0..<6 {
            svc.recordEncounter(slug: "lacto", wasCorrect: true)
        }
        #expect(svc.masteryScore(forSlug: "lacto") > 0)
    }

    // MARK: - Frontier + recommendation

    @Test("frontierSlugs — flat catalog returns all unmastered")
    func frontierSlugs_flatCatalog_allUnmastered() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto, bifido], defaults: makeDefaults())
        let frontier = svc.frontierSlugs()
        #expect(frontier == ["lacto", "bifido"])
    }

    @Test("recommendedNextMicrobe — nil when discovered set is empty")
    func recommendedNextMicrobe_emptyDiscovered_isNil() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: makeDefaults())
        #expect(svc.recommendedNextMicrobe(among: []) == nil)
    }

    @Test("recommendedNextMicrobe — picks the discovered microbe with lowest mastery")
    func recommendedNextMicrobe_picksLowestMastery() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto, bifido], defaults: makeDefaults())
        // Push bifido higher than lacto via correct encounters
        for _ in 0..<4 { svc.recordEncounter(slug: "bifido", wasCorrect: true) }
        svc.recordEncounter(slug: "lacto", wasCorrect: false)
        let recommendation = svc.recommendedNextMicrobe(among: ["lacto", "bifido"])
        #expect(recommendation == "lacto", "Lower-mastery slug should surface first")
    }

    @Test("recommendedNextMicrobe — stable alphabetic tiebreak on equal mastery")
    func recommendedNextMicrobe_stableTiebreak() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto, bifido], defaults: makeDefaults())
        // Both unseen → both at mastery 0; alphabetic tiebreak picks "bifido"
        let recommendation = svc.recommendedNextMicrobe(among: ["lacto", "bifido"])
        #expect(recommendation == "bifido", "Alphabetic order is the canonical tiebreak")
    }

    @Test("recommendedNextMicrobe — excludes undiscovered microbes")
    func recommendedNextMicrobe_excludesUndiscovered() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let bifido = makeMicrobe(slug: "bifido", displayName: "Bifido", firstKit: 1)
        let svc = MicrobeMasteryService(catalog: [lacto, bifido], defaults: makeDefaults())
        // Only "lacto" discovered → recommend lacto even though bifido is also frontier
        let recommendation = svc.recommendedNextMicrobe(among: ["lacto"])
        #expect(recommendation == "lacto")
    }

    // MARK: - Persistence

    @Test("persistence — encounters survive across instance restart")
    func persistence_survivesRestart() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let defaults = makeDefaults()
        let svc1 = MicrobeMasteryService(catalog: [lacto], defaults: defaults)
        svc1.recordEncounter(slug: "lacto", wasCorrect: true)
        let svc2 = MicrobeMasteryService(catalog: [lacto], defaults: defaults)
        #expect(svc2.records["lacto"]?.attemptCount == 1)
    }

    @Test("clearForTesting — wipes records + persisted store")
    func clearForTesting_wipesEverything() {
        let lacto = makeMicrobe(slug: "lacto", displayName: "Lacto", firstKit: 1)
        let defaults = makeDefaults()
        let svc = MicrobeMasteryService(catalog: [lacto], defaults: defaults)
        svc.recordEncounter(slug: "lacto", wasCorrect: true)
        svc.clearForTesting()
        #expect(svc.records.isEmpty)
        let svc2 = MicrobeMasteryService(catalog: [lacto], defaults: defaults)
        #expect(svc2.records.isEmpty)
    }

    // MARK: - MicrobeMasteryRecord value-type properties

    @Test("MicrobeMasteryRecord.recentAccuracy — empty window returns 0")
    func record_recentAccuracy_emptyIsZero() {
        let record = MicrobeMasteryRecord()
        #expect(record.recentAccuracy == 0)
    }

    @Test("MicrobeMasteryRecord.recentAccuracy — all correct returns 1")
    func record_recentAccuracy_allCorrectIsOne() {
        let record = MicrobeMasteryRecord(recentOutcomes: [true, true, true])
        #expect(record.recentAccuracy == 1)
    }

    @Test("MicrobeMasteryRecord.recentAccuracy — mixed returns expected ratio")
    func record_recentAccuracy_mixedIsRatio() {
        let record = MicrobeMasteryRecord(recentOutcomes: [true, false, true, false])
        #expect(record.recentAccuracy == 0.5)
    }
}
