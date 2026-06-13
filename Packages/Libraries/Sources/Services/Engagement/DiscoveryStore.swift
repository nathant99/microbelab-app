import Foundation
import Observation

/// Persists the set of microbe slugs the kid has "met" — sourced from the
/// codex tap-to-discover surface AND from `ExploreView` (rare-microbe
/// sightings + the curious-explorer easter egg both surface a canonical
/// slug; persisting the meet keeps the codex card in sync).
///
/// Storage: UserDefaults, mirrors the `MentorRecallStore` / `StreakStore`
/// pattern (on-device only per `.claude/rules/age-assurance.md` § Portfolio
/// Status — slugs are stable enum-style identifiers, no PII).
///
/// Trauma-informed posture: discovery is additive only — the store never
/// "loses" a microbe. There's no fail state. A kid can discover at their
/// own pace; the codex never frames undiscovered cards as failure.
///
/// Wiring path (closes the codex axis of `MasteryMomentDetector`):
/// 1. `MicrobeCodexView` reads `discoveredSlugs` for the per-card
///    `isDiscovered` flag.
/// 2. When the kid taps a `???` card the view calls `markDiscovered(slug:)`,
///    which writes through to UserDefaults + flips the card's display.
/// 3. After every write the view calls `recordCodexDiscovery(totalDiscovered:
///    totalAvailable:)` on `MasteryMomentDetector`; reaching the catalog
///    size (12 / 12) fires the `.codexMaster` once-per-session moment.
/// 4. `ExploreView.refreshMentorCue` + the easter-egg cue + the
///    rare-sighting cue ALL call `markDiscovered(slug:)` for the microbe
///    they reference, so meets the kid encounters in the microscope flow
///    keep the codex synchronized without requiring an explicit tap.
@MainActor
@Observable
public final class DiscoveryStore {
    public static let userDefaultsKey = "com.microbelab.discovery.slugs"

    public private(set) var discoveredSlugs: Set<String>

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.stringArray(forKey: Self.userDefaultsKey) ?? []
        self.discoveredSlugs = Set(stored)
    }

    /// Append `slug` to the persisted discovery set. Idempotent — repeated
    /// calls with the same slug are no-ops + don't trigger an observation
    /// update. Trauma-safe: never removes a slug, never re-orders.
    public func markDiscovered(slug: String) {
        guard !discoveredSlugs.contains(slug) else { return }
        discoveredSlugs.insert(slug)
        defaults.set(Array(discoveredSlugs), forKey: Self.userDefaultsKey)
    }

    /// Wipe persisted state. Test-only — the production surface never
    /// shrinks a kid's discovery set.
    public func clearForTesting() {
        discoveredSlugs.removeAll()
        defaults.removeObject(forKey: Self.userDefaultsKey)
    }
}
