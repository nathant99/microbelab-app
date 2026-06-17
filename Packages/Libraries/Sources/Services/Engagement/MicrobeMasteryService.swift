import Foundation
import Observation
import Models
import ForgeGamification

/// Per-microbe mastery tracking layered over the 24-microbe cast. Uses
/// `ForgeGamification.SpacedRepetitionEngine` (FSRS-6 retention model) + a
/// rolling-window recent-accuracy mix to compute a per-microbe mastery score,
/// then surfaces a single "Ready to look closer at: X" caption in
/// `MicrobeCodexView` for the kid to follow at their own pace.
///
/// **Per-microbe state**: `MicrobeMasteryRecord` wraps `ForgeGamification.FSRSState`
/// + a bounded rolling-window of recent encounter outcomes. `masteryScore` blends
/// FSRS-6 retrievability (60% weight) with rolling-window accuracy (40% weight) so
/// a brand-new high-stability microbe the kid has just gotten right several times
/// reads as "mastered" without waiting for time to elapse — same shape as
/// `ForgeMasteryEngine.TopicMasteryState.masteryScore` (will swap to that engine
/// once ForgeKit's 1.0 stable lands; rc.2 is currently pre-release).
///
/// **Encounter signals**: `recordEncounter(slug:wasCorrect:elapsedSeconds:)` fires
/// from two surfaces:
///
/// 1. `MicrobeCodexView` tap-to-discover (the kid actively meets the microbe)
/// 2. `MicrobeCodexView` tap-to-reopen on already-discovered microbes
///    (reinforcement — bumps the FSRS-6 retention curve + rolling accuracy)
///
/// Quiz-side encounter wiring (a per-question kit standard → microbe-slug map)
/// is deferred to a focused follow-up round.
///
/// **Surface API**: `recommendedNextMicrobe(among discovered:)` returns one
/// microbe slug the kid is ready to deepen — the lowest-mastery discovered
/// microbe whose habitat-prerequisite earlier-kit microbes have all reached
/// `masteryThreshold`. Returns `nil` when no recommendation exists. The
/// habitat-prereq graph is frozen at construction from `catalog`'s
/// `(slug, firstKit, preferredEnvironment)` tuples; it's cycle-free because
/// `firstKit` is monotonic.
///
/// **Trauma-informed posture**: the surface NEVER frames a low-mastery microbe
/// as a deficiency. The caption copy lives in `MicrobeCodexView` ("Ready to
/// look closer at: \(name)") and is stoplist-pinned by view-layer tests when
/// the consumer wiring lands. This service ships pure-derivation; the consumer
/// chooses how (or whether) to surface the recommendation.
///
/// **Privacy posture**: per `.claude/rules/age-assurance.md` § Portfolio Status,
/// counts + FSRS state + rolling outcomes only — never PII. State persists
/// to UserDefaults under one canonical key.
@MainActor
@Observable
public final class MicrobeMasteryService {
    public static let userDefaultsKey = "com.microbelab.microbe.mastery.records"

    /// Default rolling-window capacity. Mirrors the
    /// `ForgeMasteryEngine.MasteryUpdater(recentWindowSize:)` portfolio default.
    public static let defaultRecentWindowSize = 8

    /// Score above which a microbe counts as mastered for the purposes of
    /// gating later-kit habitat-share recommendations.
    public static let defaultMasteryThreshold: Double = 0.85

    /// Per-microbe-slug mastery records. Pure-additive — recorded encounters
    /// extend rolling-window outcomes; no consumer ever shrinks the map.
    public private(set) var records: [String: MicrobeMasteryRecord]

    /// Frozen-at-construction prerequisite topology. Key = microbe slug;
    /// value = the set of microbe slugs that precede it in the same habitat.
    /// Used by `frontierSlugs()` to gate later-kit recommendations until the
    /// earlier-kit habitat cohort has reached mastery.
    public let habitatPrerequisites: [String: Set<String>]

    private let defaults: UserDefaults
    private let srs: SpacedRepetitionEngine
    private let recentWindowSize: Int
    private let masteryThreshold: Double

    public init(
        catalog: [MicrobeCharacter],
        defaults: UserDefaults = .standard,
        srs: SpacedRepetitionEngine = SpacedRepetitionEngine(desiredRetention: 0.9),
        recentWindowSize: Int = MicrobeMasteryService.defaultRecentWindowSize,
        masteryThreshold: Double = MicrobeMasteryService.defaultMasteryThreshold
    ) {
        self.habitatPrerequisites = Self.buildPrerequisites(from: catalog)
        self.defaults = defaults
        self.srs = srs
        self.recentWindowSize = recentWindowSize
        self.masteryThreshold = masteryThreshold
        if let data = defaults.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: MicrobeMasteryRecord].self, from: data) {
            self.records = decoded
        } else {
            self.records = [:]
        }
    }

    /// Record one encounter against a microbe. Pure-additive — extends the
    /// rolling-window outcome list and bumps the FSRS-6 retention state.
    /// `elapsedSeconds` flows through to the FSRS quality mapping; pass a
    /// realistic time (e.g., `Date.now.timeIntervalSince(viewAppearedAt)`)
    /// or default to 5s for non-quiz surfaces (codex tap).
    public func recordEncounter(
        slug: String,
        wasCorrect: Bool,
        elapsedSeconds: Double = 5.0,
        now: Date = .now
    ) {
        guard habitatPrerequisites[slug] != nil else { return }
        let prior = records[slug] ?? MicrobeMasteryRecord()
        var window = prior.recentOutcomes
        window.append(wasCorrect)
        if window.count > recentWindowSize {
            window.removeFirst(window.count - recentWindowSize)
        }
        // FSRS quality mapping: correct = 5 (easy), incorrect = 2 (hard).
        // Quiz-with-hints quality (3-4 band) lands when the quiz wiring
        // surfaces in a follow-up round.
        let quality = wasCorrect ? 5 : 2
        let newFSRS = srs.reviewItem(state: prior.fsrs, quality: quality, reviewDate: now)
        records[slug] = MicrobeMasteryRecord(
            fsrs: newFSRS,
            attemptCount: prior.attemptCount + 1,
            recentOutcomes: window
        )
        persist()
    }

    /// Per-microbe mastery score in [0, 1]. Returns 0 for unseen microbes.
    /// Mirrors `ForgeMasteryEngine.TopicMasteryState.masteryScore` derivation
    /// so future migration is a one-call swap.
    public func masteryScore(forSlug slug: String, now: Date = .now) -> Double {
        guard let record = records[slug] else { return 0 }
        guard record.attemptCount > 0 else { return 0 }
        let elapsedDays = max(0, now.timeIntervalSince(record.fsrs.lastReview) / 86400.0)
        let retrievability = record.fsrs.retrievability(elapsedDays: elapsedDays)
        let accuracy = record.recentAccuracy
        let score = (0.6 * retrievability) + (0.4 * accuracy)
        return max(0, min(1, score))
    }

    /// Slugs whose mastery has reached `masteryThreshold`.
    public func masteredSlugs(now: Date = .now) -> Set<String> {
        var mastered: Set<String> = []
        for slug in habitatPrerequisites.keys {
            if masteryScore(forSlug: slug, now: now) >= masteryThreshold {
                mastered.insert(slug)
            }
        }
        return mastered
    }

    /// Slugs whose habitat prerequisites are met but mastery has NOT been
    /// reached. These are the "ready to look closer" candidates.
    public func frontierSlugs(now: Date = .now) -> Set<String> {
        let mastered = masteredSlugs(now: now)
        var frontier: Set<String> = []
        for (slug, prereqs) in habitatPrerequisites {
            if mastered.contains(slug) { continue }
            let allPrereqsMet = prereqs.allSatisfy { mastered.contains($0) }
            if allPrereqsMet {
                frontier.insert(slug)
            }
        }
        return frontier
    }

    /// Returns one microbe slug the kid is ready to deepen — picks the
    /// lowest-mastery frontier topic the kid has already discovered. Returns
    /// `nil` when no recommendation exists. Trauma-informed posture: callers
    /// SHOULD treat `nil` as "no nudge today" (not as failure).
    public func recommendedNextMicrobe(among discovered: Set<String>, now: Date = .now) -> String? {
        guard !discovered.isEmpty else { return nil }
        let frontier = frontierSlugs(now: now)
        let candidates = frontier.intersection(discovered)
        guard !candidates.isEmpty else { return nil }
        // Sort by (mastery ascending, slug alphabetic ascending) for stable
        // ordering across recommendations.
        return candidates.sorted { (lhs, rhs) in
            let lScore = masteryScore(forSlug: lhs, now: now)
            let rScore = masteryScore(forSlug: rhs, now: now)
            if lScore != rScore { return lScore < rScore }
            return lhs < rhs
        }.first
    }

    /// Wipe persisted state. Test-only — the production surface never
    /// shrinks a kid's mastery map.
    public func clearForTesting() {
        records.removeAll()
        defaults.removeObject(forKey: Self.userDefaultsKey)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            defaults.set(data, forKey: Self.userDefaultsKey)
        } catch {
            DebugLog.error("MicrobeMasteryService.persist failed", error: error)
        }
    }

    /// Build the habitat-prerequisite map: microbe X has prerequisites = the
    /// set of microbes Y where `Y.firstKit < X.firstKit` AND
    /// `Y.preferredEnvironment == X.preferredEnvironment`. Cycle-free because
    /// `firstKit` is monotonic across the prerequisite relation.
    nonisolated static func buildPrerequisites(from catalog: [MicrobeCharacter]) -> [String: Set<String>] {
        var out: [String: Set<String>] = [:]
        for microbe in catalog {
            let prereqs = catalog
                .filter { other in
                    other.slug != microbe.slug
                    && other.firstKit < microbe.firstKit
                    && other.preferredEnvironment == microbe.preferredEnvironment
                }
                .map(\.slug)
            out[microbe.slug] = Set(prereqs)
        }
        return out
    }
}

/// One persisted record of per-microbe mastery state. Wraps the FSRS-6
/// retention state + a bounded rolling-window of recent encounter outcomes.
/// Pure value type — Codable for UserDefaults persistence.
public nonisolated struct MicrobeMasteryRecord: Codable, Sendable, Equatable {
    public var fsrs: FSRSState
    public var attemptCount: Int
    public var recentOutcomes: [Bool]

    public init(
        fsrs: FSRSState = FSRSState(),
        attemptCount: Int = 0,
        recentOutcomes: [Bool] = []
    ) {
        self.fsrs = fsrs
        self.attemptCount = attemptCount
        self.recentOutcomes = recentOutcomes
    }

    /// Accuracy of the rolling window in [0, 1]. Returns 0 when the window
    /// is empty (no encounters recorded yet).
    public var recentAccuracy: Double {
        guard !recentOutcomes.isEmpty else { return 0 }
        let correct = recentOutcomes.filter { $0 }.count
        return Double(correct) / Double(recentOutcomes.count)
    }
}
