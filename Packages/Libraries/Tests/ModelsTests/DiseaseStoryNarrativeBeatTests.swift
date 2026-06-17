import Foundation
import Testing
@testable import Models

@Suite("DiseaseStoryNarrativeBeat")
nonisolated struct DiseaseStoryNarrativeBeatTests {

    @Test func canonicalBeatOrder() {
        // Pinned per the pedagogy spine in `Docs/TECHNICAL_DESIGN.md` § Phase 3
        // + the doc-comment table on DiseaseStoryNarrativeBeat. A future
        // refactor must not silently reorder the beats.
        #expect(DiseaseStoryNarrativeBeat.introduction.index == 0)
        #expect(DiseaseStoryNarrativeBeat.witness.index == 1)
        #expect(DiseaseStoryNarrativeBeat.action.index == 2)
        #expect(DiseaseStoryNarrativeBeat.reflection.index == 3)
    }

    @Test func canonicalCaseCountMatchesDeclaration() {
        // Load-bearing: the scaffold catalog math (4 arcs × 4 beats = 16)
        // assumes 4 beats. A new beat case requires updating the catalog.
        #expect(DiseaseStoryNarrativeBeat.allCases.count == 4)
    }

    @Test func canonicalRawValueStability() {
        // Stable raw values so a future Codable persistence layer + the
        // composite id `<arc>.<beat>` don't drift if cases are renamed.
        #expect(DiseaseStoryNarrativeBeat.introduction.rawValue == "introduction")
        #expect(DiseaseStoryNarrativeBeat.witness.rawValue == "witness")
        #expect(DiseaseStoryNarrativeBeat.action.rawValue == "action")
        #expect(DiseaseStoryNarrativeBeat.reflection.rawValue == "reflection")
    }

    @Test(arguments: DiseaseStoryNarrativeBeat.allCases)
    func displayTitleTraumaSafeRegister(beat: DiseaseStoryNarrativeBeat) {
        // Stoplist per `.claude/rules/trauma-informed-content.md`. The
        // beat-level display titles must avoid warfare / shame / threat /
        // fear-induction lexicon even though they're structural primitives.
        let stoplist: [String] = [
            "fight", "attack", "destroy", "kill", "war", "enemy",
            "battle", "weapon", "soldier", "warrior", "germ",
            "scary", "fear", "shame", "blame", "lose", "lost",
            "wrong", "bad",
        ]
        let normalized = beat.displayTitle.lowercased()
        for forbidden in stoplist {
            #expect(
                !normalized.contains(forbidden),
                "beat \(beat) display title contains forbidden token '\(forbidden)': \(beat.displayTitle)"
            )
        }
    }

    @Test(arguments: DiseaseStoryNarrativeBeat.allCases)
    func primitiveTraumaSafeRegister(beat: DiseaseStoryNarrativeBeat) {
        // Same stoplist applies to the per-beat curriculum primitive.
        let stoplist: [String] = [
            "fight", "attack", "destroy", "kill", "war", "enemy",
            "battle", "weapon", "soldier", "warrior", "germ",
            "scary", "fear", "shame", "blame",
        ]
        let normalized = beat.primitive.lowercased()
        for forbidden in stoplist {
            #expect(
                !normalized.contains(forbidden),
                "beat \(beat) primitive contains forbidden token '\(forbidden)': \(beat.primitive)"
            )
        }
    }

    @Test func canonicalCatalogTotalEntryCount() {
        // Load-bearing for the scene scaffold + view scaffold + ADR-016
        // closure tracking. 4 arcs × 4 beats = 16 records.
        #expect(DiseaseStoryNarrativeCatalog.canonicalRecords.count == 16)
        #expect(DiseaseStoryNarrativeCatalog.totalEntries == 16)
    }

    @Test func catalogIncludesEveryArcAndBeatCombination() {
        // Pin every (arc, beat) pair so a future filter / refactor can't
        // silently drop a combination. The composite id makes the
        // deduplication explicit.
        let ids = Set(DiseaseStoryNarrativeCatalog.canonicalRecords.map { $0.id })
        #expect(ids.count == 16)
        for arc in DiseaseStoryArc.allCases {
            for beat in DiseaseStoryNarrativeBeat.allCases {
                #expect(ids.contains("\(arc.rawValue).\(beat.rawValue)"))
            }
        }
    }

    @Test func catalogShipsAllEntriesAsPlaceholder() {
        // Per ADR-016 every entry ships as `.placeholder` until reviewer-
        // signoff lands. The consuming view layer gates rendering on the
        // authoring state; a regression here would break the trauma-safe
        // posture.
        for record in DiseaseStoryNarrativeCatalog.canonicalRecords {
            #expect(record.authoring == .placeholder)
        }
    }

    @Test func beatsForArcReturnsFourEntriesInCanonicalOrder() {
        // The view scaffold filters by arc; pin the per-arc shape so a
        // future refactor can't silently change the per-arc beat count
        // OR the per-arc beat order.
        for arc in DiseaseStoryArc.allCases {
            let beats = DiseaseStoryNarrativeCatalog.beats(for: arc)
            #expect(beats.count == 4)
            #expect(beats[0].beat == .introduction)
            #expect(beats[1].beat == .witness)
            #expect(beats[2].beat == .action)
            #expect(beats[3].beat == .reflection)
            #expect(beats.allSatisfy { $0.arc == arc })
        }
    }

    @Test func beatDisplayTitleCombinesArcAndBeat() {
        // Pin the composite-display format the view scaffold surfaces in
        // the status chip + accessibility label.
        let record = DiseaseStoryNarrativeBeatRecord(arc: .handwashing, beat: .introduction)
        #expect(record.beatDisplayTitle == "How soap helps — At rest")
    }

    @Test func recordIdIsCompositeAndStable() {
        // Required for List + ForEach Identifiable conformance in the
        // SwiftUI consumer; a regression here would collapse multiple
        // beats into the same SwiftUI identity bucket.
        let r1 = DiseaseStoryNarrativeBeatRecord(arc: .vaccinePriming, beat: .action)
        #expect(r1.id == "vaccinePriming.action")
        let r2 = DiseaseStoryNarrativeBeatRecord(arc: .outbreakRecovery, beat: .reflection)
        #expect(r2.id == "outbreakRecovery.reflection")
    }

    @Test func recordEqualityIncludesAuthoringState() {
        let placeholder = DiseaseStoryNarrativeBeatRecord(arc: .handwashing, beat: .witness)
        let draft = DiseaseStoryNarrativeBeatRecord(
            arc: .handwashing,
            beat: .witness,
            authoring: .draftAwaitingReview
        )
        #expect(placeholder != draft)
    }

    @Test func recordCodableRoundTripPreservesAuthoring() throws {
        // Forward-compat: when the reviewer pathway eventually persists
        // per-beat authoring state, Codable shape must survive a
        // round-trip without losing the authoring value.
        let original = DiseaseStoryNarrativeBeatRecord(
            arc: .vaccinePriming,
            beat: .reflection,
            authoring: .reviewerSignedOff
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DiseaseStoryNarrativeBeatRecord.self, from: data)
        #expect(decoded == original)
        #expect(decoded.authoring == .reviewerSignedOff)
    }
}
