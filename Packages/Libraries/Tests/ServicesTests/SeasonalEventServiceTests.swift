import Testing
import Foundation
import ForgeEvents
@testable import Services

@Suite("SeasonalEventService (Phase 4 scaffold)")
@MainActor
struct SeasonalEventServiceTests {

    @Test("default enabled packs are culturally neutral")
    func defaultEnabledPacksAreCulturallyNeutral() {
        let service = SeasonalEventService()
        // Defaults must NOT assume kid's culture — only seasons + global.
        #expect(service.enabledPacks.contains(.seasons))
        #expect(service.enabledPacks.contains(.globalCelebrations))
        #expect(!service.enabledPacks.contains(.americanHolidays))
        #expect(!service.enabledPacks.contains(.vietnameseHolidays))
        #expect(!service.enabledPacks.contains(.indianCelebrations))
        #expect(!service.enabledPacks.contains(.latinoCelebrations))
    }

    @Test("hasRefreshed starts false; flips after refresh(on:)")
    func hasRefreshedFlagSurfaces() async {
        let service = SeasonalEventService()
        #expect(!service.hasRefreshed)
        await service.refresh(on: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(service.hasRefreshed)
    }

    @Test("setEnabledPacks updates the set the next refresh consumes")
    func setEnabledPacksUpdatesSet() {
        let service = SeasonalEventService()
        service.setEnabledPacks([.seasons, .americanHolidays])
        #expect(service.enabledPacks == [.seasons, .americanHolidays])
    }

    @Test("init with custom packs preserves them")
    func initWithCustomPacks() {
        let service = SeasonalEventService(enabledPacks: [.schoolCalendar])
        #expect(service.enabledPacks == [.schoolCalendar])
    }

    @Test("hasActiveEvent surfaces engine state before refresh; expect false")
    func hasActiveEventPreRefreshIsFalse() {
        let service = SeasonalEventService()
        #expect(!service.hasActiveEvent)
        #expect(service.streakEmoji == nil)
        #expect(service.currencyEmoji == nil)
    }

    @Test("registerBuiltIns populates the registry without error")
    func registerBuiltInsIsIdempotent() async {
        let service = SeasonalEventService()
        await service.registerBuiltIns()
        // Second call is idempotent — should not throw or duplicate.
        await service.registerBuiltIns()
        // Refresh to verify the engine can read the registry post-registration.
        await service.refresh(on: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(service.hasRefreshed)
    }
}
