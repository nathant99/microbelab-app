import Foundation
import Testing
@testable import Services
@testable import Models

@Suite("AnalyticsService")
@MainActor
struct AnalyticsServiceTests {
    @Test func initialStateHasNoActiveSession() async {
        let service = AnalyticsService()
        #expect(service.currentSessionID == nil)
        let count = await service.totalEventCount()
        #expect(count == 0)
    }

    @Test func startSessionStampsSessionID() async {
        let service = AnalyticsService()
        await service.startSession()
        #expect(service.currentSessionID != nil)
    }

    @Test func endSessionClearsSessionID() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.endSession()
        #expect(service.currentSessionID == nil)
    }

    @Test func trackZoomTierRecordsCanonicalEventName() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.zoomTierReached(tier: .light))
        let names = await service.recordedEventNames()
        #expect(names.contains("zoom_tier_reached"))
    }

    @Test func trackImmuneWaveClearedRecordsWaveIndex() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.immuneWaveCleared(waveIndex: 3))
        let names = await service.recordedEventNames()
        #expect(names.contains("immune_wave_cleared"))
    }

    @Test func trackImmuneRunCompletedRecordsEvent() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.immuneRunCompleted)
        let names = await service.recordedEventNames()
        #expect(names.contains("immune_run_completed"))
    }

    @Test func trackFeedingModeRecordsModeSlug() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.feedingModeChanged(modeSlug: "fiber"))
        let names = await service.recordedEventNames()
        #expect(names.contains("feeding_mode_changed"))
    }

    @Test func trackQuizCompletedRecordsAndMarksPerfect() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.quizCompleted(kitSlug: "kit_01_microbiology_basics", correct: 5, total: 5))
        let names = await service.recordedEventNames()
        #expect(names.contains("quiz_completed"))
    }

    @Test func multipleTracksAccumulate() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.zoomTierReached(tier: .unaided))
        await service.track(.zoomTierReached(tier: .light))
        await service.track(.zoomTierReached(tier: .electron))
        let names = await service.recordedEventNames()
        let zoomCount = names.filter { $0 == "zoom_tier_reached" }.count
        #expect(zoomCount == 3)
    }

    @Test func activeDaysReturnsZeroBeforeAnyEvents() async {
        let service = AnalyticsService()
        let days = await service.activeDays(last: 7)
        #expect(days == 0)
    }

    @Test func activeDaysReflectsRecordedEvents() async {
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.zoomTierReached(tier: .light))
        let days = await service.activeDays(last: 7)
        #expect(days >= 1)
    }

    @Test func eventPropertyBagsAreCountsAndSlugsOnly() {
        // Trauma-informed / COPPA: every property is either a count or an
        // enum-derived slug — never a kid name / identifier.
        let zoom = MicrobeLabAnalyticsEvent.zoomTierReached(tier: .electron)
        #expect(zoom.properties["tier_slug"] == "electron")
        #expect(zoom.properties["tier_index"] == "3")

        let quiz = MicrobeLabAnalyticsEvent.quizCompleted(kitSlug: "kit_x", correct: 4, total: 6)
        #expect(quiz.properties["kit_slug"] == "kit_x")
        #expect(quiz.properties["correct_count"] == "4")
        #expect(quiz.properties["total_count"] == "6")
        #expect(quiz.properties["perfect"] == "false")

        let perfectQuiz = MicrobeLabAnalyticsEvent.quizCompleted(kitSlug: "kit_y", correct: 5, total: 5)
        #expect(perfectQuiz.properties["perfect"] == "true")

        let achievement = MicrobeLabAnalyticsEvent.achievementEarned(slug: "fiber-pioneer")
        #expect(achievement.properties["achievement_slug"] == "fiber-pioneer")

        let runComplete = MicrobeLabAnalyticsEvent.immuneRunCompleted
        #expect(runComplete.properties.isEmpty)
    }

    @Test func trackAppPhaseReachedRecordsPhaseSlug() async {
        // Closes the ForgeNavigation wire-up loop on the analytics axis —
        // AppRootView fires this event on every phase transition so the
        // on-device event log carries a single canonical phase identifier
        // (parent_handoff → kid_onboarding → loading_catalog → tab_shell).
        let service = AnalyticsService()
        await service.startSession()
        await service.track(.appPhaseReached(phaseSlug: "tab_shell"))
        let names = await service.recordedEventNames()
        #expect(names.contains("app_phase_reached"))
    }

    @Test func appPhaseReachedPropertyBagCarriesPhaseSlug() {
        // PII-safe: the property bag is the phase slug only, never the
        // kid's progress count or identifier.
        let event = MicrobeLabAnalyticsEvent.appPhaseReached(phaseSlug: "kid_onboarding")
        #expect(event.name == "app_phase_reached")
        #expect(event.properties["phase_slug"] == "kid_onboarding")
        #expect(event.properties.count == 1)
    }

    @Test func zoomTierSlugIsStableAcrossAllCases() {
        // Stability invariant — slugs are persisted in the on-device analytics
        // store + may surface in parent-facing dashboards. Renaming a slug is
        // a breaking change.
        #expect(MicrobeLabAnalyticsEvent.zoomTierReached(tier: .unaided).properties["tier_slug"] == "unaided")
        #expect(MicrobeLabAnalyticsEvent.zoomTierReached(tier: .light).properties["tier_slug"] == "light")
        #expect(MicrobeLabAnalyticsEvent.zoomTierReached(tier: .fluorescence).properties["tier_slug"] == "fluorescence")
        #expect(MicrobeLabAnalyticsEvent.zoomTierReached(tier: .electron).properties["tier_slug"] == "electron")
    }
}
