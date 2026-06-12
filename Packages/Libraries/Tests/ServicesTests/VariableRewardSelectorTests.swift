import Foundation
import Testing
@testable import Services

@Suite("VariableRewardSelector")
struct VariableRewardSelectorTests {
    private let slugs = ["lacto", "yeast", "photo", "net", "spore", "guard"]

    @Test func zeroOrNegativeSessionCountAlwaysReturnsNil() {
        #expect(VariableRewardSelector.select(forSessionCount: 0, microbeSlugs: slugs) == nil)
        #expect(VariableRewardSelector.select(forSessionCount: -1, microbeSlugs: slugs) == nil)
    }

    @Test func deterministicForSameInput() {
        // The selector is a pure function; same session count yields same
        // result every call. This is the property that makes the rewards
        // feel random to the kid (they don't see the source) while being
        // testable + reproducible.
        let first = VariableRewardSelector.select(forSessionCount: 5, microbeSlugs: slugs)
        let second = VariableRewardSelector.select(forSessionCount: 5, microbeSlugs: slugs)
        #expect(first == second)
    }

    @Test func emptySlugListFallsThroughToMentorMoment() {
        // If catalog is empty and the session lands on a reward, we should
        // never return `.rareMicrobeSighting` with an empty slug. The
        // selector falls through to the mentor variant.
        let sample = (1...200).compactMap { n in
            VariableRewardSelector.select(forSessionCount: n, microbeSlugs: [])
        }
        // No rare-microbe entries on an empty catalog.
        for reward in sample {
            if case .rareMicrobeSighting = reward {
                Issue.record("rareMicrobeSighting fired on empty slug list")
            }
        }
    }

    @Test func cadenceLooksApproximatelyOneInFive() {
        // Across 1000 simulated sessions the hit rate should land near 20%
        // (1 in 5). Loose bound: 12% - 28%. Tight enough to catch a
        // misbehaving mixer (e.g. always-nil or always-hit) but loose
        // enough that splitmix mod-5 lumpiness doesn't trip false fails.
        let hits = (1...1000).filter { n in
            VariableRewardSelector.select(forSessionCount: n, microbeSlugs: slugs) != nil
        }.count
        let rate = Double(hits) / 1000.0
        #expect(rate > 0.12 && rate < 0.28, "Hit rate \(rate) outside [0.12, 0.28]")
    }

    @Test func rareMicrobeSightingPicksFromProvidedSlugs() {
        let sample = (1...500).compactMap { n in
            VariableRewardSelector.select(forSessionCount: n, microbeSlugs: slugs)
        }
        for reward in sample {
            if case .rareMicrobeSighting(let slug) = reward {
                #expect(slugs.contains(slug), "Selector returned slug not in input list: \(slug)")
            }
        }
    }

    @Test func bothKindsAppearAcrossSampleWindow() {
        var sawMicrobe = false
        var sawMentor = false
        for n in 1...500 {
            switch VariableRewardSelector.select(forSessionCount: n, microbeSlugs: slugs) {
            case .rareMicrobeSighting: sawMicrobe = true
            case .specialMentorMoment: sawMentor = true
            case .none: break
            }
            if sawMicrobe && sawMentor { break }
        }
        #expect(sawMicrobe, "Sample window never produced rareMicrobeSighting")
        #expect(sawMentor, "Sample window never produced specialMentorMoment")
    }

    @Test func customSaltGivesDifferentSequence() {
        // Drives the future per-portfolio-app pivot — a different app's
        // selector should disagree with MicrobeLab's on at least one
        // session within the sample window.
        let altSalt: UInt64 = 0x1234_5678_9ABC_DEF0
        let disagreement = (1...100).contains { n in
            let a = VariableRewardSelector.select(forSessionCount: n, microbeSlugs: slugs)
            let b = VariableRewardSelector.select(forSessionCount: n, microbeSlugs: slugs, salt: altSalt)
            return a != b
        }
        #expect(disagreement)
    }
}
