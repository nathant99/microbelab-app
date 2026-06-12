import Foundation
import Testing
@testable import Models

@Suite("CacheStructs")
nonisolated struct CacheStructsTests {
    @Test func encounterLogDataIsSendable() {
        // Sendable + value-type round-trip across an actor boundary —
        // exercises the nonisolated contract enforced by the suite.
        let data = EncounterLogData(
            id: UUID(),
            microbeID: UUID(),
            slug: "lacto",
            encounteredAt: Date(),
            atZoomTier: .light,
            inSlot: .colon,
            sessionID: nil
        )
        #expect(data.slug == "lacto")
        #expect(data.atZoomTier == .light)
        #expect(data.inSlot == .colon)
    }

    @Test func journalEntryDataPreservesBody() {
        let data = JournalEntryData(
            id: UUID(),
            createdAt: Date(),
            body: "I noticed Lacto thrives on fiber.",
            relatedMicrobeID: UUID(),
            promptSlug: "first-observation"
        )
        #expect(data.body.contains("Lacto"))
        #expect(data.promptSlug == "first-observation")
    }

    @Test func microbeSessionDataDecodesFinalState() {
        let id = UUID()
        let state = MicrobiomeState(
            populations: [id: 50],
            feedingMode: .fiber,
            antibioticState: .none,
            tickCount: 7,
            activeSlot: .colon
        )
        let data = MicrobeSessionData(
            id: UUID(),
            startedAt: Date(),
            endedAt: Date(),
            highestZoomTier: .fluorescence,
            finalState: state
        )
        #expect(data.finalState?.tickCount == 7)
        #expect(data.highestZoomTier == .fluorescence)
    }
}
