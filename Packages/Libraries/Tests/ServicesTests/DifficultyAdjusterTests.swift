import Foundation
import Testing
@testable import Services

@Suite("DifficultyAdjuster")
struct DifficultyAdjusterTests {
    @Test func sessionZeroAndOneStartIntroductory() {
        #expect(DifficultyAdjuster.from(sessionCount: 0).level == .introductory)
        #expect(DifficultyAdjuster.from(sessionCount: 1).level == .introductory)
        #expect(DifficultyAdjuster.from(sessionCount: 2).level == .introductory)
    }

    @Test func sessionsThreeAndFourMoveToStandard() {
        #expect(DifficultyAdjuster.from(sessionCount: 3).level == .standard)
        #expect(DifficultyAdjuster.from(sessionCount: 4).level == .standard)
    }

    @Test func sessionFivePlusGoesChallenging() {
        #expect(DifficultyAdjuster.from(sessionCount: 5).level == .challenging)
        #expect(DifficultyAdjuster.from(sessionCount: 50).level == .challenging)
    }

    @Test func simplifyChallengePinsToIntroductoryRegardlessOfSession() {
        // The whole point of the accessibility toggle: long-term gentle
        // mode never escalates with session count.
        for count in [0, 3, 5, 100] {
            let adjuster = DifficultyAdjuster.from(
                sessionCount: count,
                simplifyChallenge: true
            )
            #expect(adjuster.level == .introductory,
                    "session \(count) with simplifyChallenge should stay introductory")
        }
    }

    // MARK: - Immune wave counts

    @Test func introductoryWaveCountsAreGentlest() {
        let adjuster = DifficultyAdjuster(level: .introductory)
        let counts = adjuster.immuneWavePathogenCounts(totalWaves: 5)
        #expect(counts == [3, 4, 5, 6, 7])
    }

    @Test func standardWaveCountsMatchOriginalPhase1Curve() {
        // Codifies the pre-DDA hardcoded curve so the refactor doesn't
        // change session 3-4 behavior.
        let adjuster = DifficultyAdjuster(level: .standard)
        let counts = adjuster.immuneWavePathogenCounts(totalWaves: 5)
        #expect(counts == [4, 6, 8, 10, 12])
    }

    @Test func challengingWaveCountsHaveDenserOpener() {
        let adjuster = DifficultyAdjuster(level: .challenging)
        let counts = adjuster.immuneWavePathogenCounts(totalWaves: 5)
        #expect(counts == [5, 7, 9, 11, 13])
    }

    @Test func waveCountsAlwaysAscendWithinASession() {
        // Trauma-informed posture: the curve climbs in every band. Kid
        // expects more pathogens at the back of the run, never fewer.
        for level in DifficultyLevel.allCases {
            let counts = DifficultyAdjuster(level: level)
                .immuneWavePathogenCounts(totalWaves: 5)
            for index in 1..<counts.count {
                #expect(counts[index] > counts[index - 1],
                        "level \(level) wave \(index) must exceed wave \(index - 1)")
            }
        }
    }

    @Test func waveCountsHonorTotalWavesArgument() {
        let adjuster = DifficultyAdjuster(level: .standard)
        #expect(adjuster.immuneWavePathogenCounts(totalWaves: 3).count == 3)
        #expect(adjuster.immuneWavePathogenCounts(totalWaves: 8).count == 8)
    }

    // MARK: - Microbiome steady threshold

    @Test func microbiomeThresholdRelaxesAtIntroductory() {
        #expect(DifficultyAdjuster(level: .introductory).microbiomeSteadyTickThreshold == 6)
    }

    @Test func microbiomeThresholdMatchesOriginalAtStandard() {
        // Pre-DDA the threshold was hardcoded as 10 in MicrobiomeView.
        #expect(DifficultyAdjuster(level: .standard).microbiomeSteadyTickThreshold == 10)
    }

    @Test func microbiomeThresholdTightensAtChallenging() {
        #expect(DifficultyAdjuster(level: .challenging).microbiomeSteadyTickThreshold == 14)
    }
}
