import Foundation
import Testing
@testable import Services

@Suite("SessionSummary")
struct SessionSummaryTests {
    private func makeSummary(microbes: Int = 0, streak: Int = 0) -> SessionSummary {
        SessionSummary(
            currentLevel: 1,
            totalXP: 0,
            currentStreak: streak,
            microbesDiscovered: microbes,
            achievementsEarned: 0
        )
    }

    @Test func headlineForRichSessionReadsWarm() {
        #expect(makeSummary(microbes: 8).headline == "You explored a lot today")
    }

    @Test func headlineForModerateSessionAcknowledgesIt() {
        #expect(makeSummary(microbes: 4).headline == "Solid session")
    }

    @Test func headlineForQuietSessionRefusesShame() {
        // The "quiet today — that's allowed" copy is load-bearing for
        // the trauma-informed posture. The session-closer NEVER shames.
        let summary = makeSummary(microbes: 0)
        #expect(summary.headline == "Quiet today — that's allowed")
        #expect(summary.headline.contains("allowed"))
    }

    @Test func previewForZeroDiscoveriesPointsAtMicroscope() {
        let preview = makeSummary(microbes: 0).nextSessionPreview
        #expect(preview.contains("zoom") || preview.contains("microbe"))
    }

    @Test func previewForZeroStreakAcknowledgesNoStreakPressure() {
        let preview = makeSummary(microbes: 4, streak: 0).nextSessionPreview
        // The zero-streak branch is the kid who came back after a break.
        // The copy must NEVER mention the broken streak or the missed
        // days. It frames "pick up where you left off" instead.
        #expect(preview.contains("pick up"))
        #expect(!preview.contains("streak"))
        #expect(!preview.contains("missed"))
    }

    @Test func previewForActiveStreakSuggestsDeepening() {
        let preview = makeSummary(microbes: 4, streak: 5).nextSessionPreview
        #expect(preview.contains("feeding mode") || preview.contains("microbiome"))
    }
}
