import Foundation
import Observation

/// Persists a small ring buffer of microbe slugs the kid has recently "met"
/// (via variable-reward sightings + codex visits) so the mentor (Cilia) can
/// surface callbacks ("Remember Lacto from yesterday? They're still here").
///
/// Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Character personality"
/// item: Vee surfaces callbacks to the player's discoveries. The store is
/// the lightweight persistence seam that makes those callbacks possible
/// without bolting onto SwiftData.
///
/// Capacity bounded to 5 entries (FIFO) so the recall surface stays
/// "recently noticed" not "exhaustive history." Trauma-informed: storing a
/// rolling window means a kid who hasn't played in months sees fresh
/// callbacks based on their LAST visits — never "you abandoned us" framing.
///
/// Privacy posture per `.claude/rules/age-assurance.md` § Portfolio Status:
/// every entry is a catalog-derived slug (no PII), persisted to
/// UserDefaults on-device only.
@MainActor
@Observable
public final class MentorRecallStore {
    public static let storageKey = "com.microbelab.mentor.recallEntries"
    public static let capacity: Int = 5

    private let defaults: UserDefaults
    public private(set) var entries: [MentorRecallEntry]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: MentorRecallStore.storageKey),
           let decoded = try? JSONDecoder().decode([MentorRecallEntry].self, from: data) {
            self.entries = decoded
        } else {
            self.entries = []
        }
    }

    /// Record that the kid "met" the named microbe. Bumps an existing entry
    /// to the front (FIFO recency) instead of accumulating duplicates so the
    /// ring buffer always reflects the kid's most recent N distinct meets.
    public func record(slug: String, at date: Date = Date()) {
        guard !slug.isEmpty else { return }
        var working = entries.filter { $0.slug != slug }
        working.insert(MentorRecallEntry(slug: slug, lastSeenAt: date), at: 0)
        if working.count > MentorRecallStore.capacity {
            working = Array(working.prefix(MentorRecallStore.capacity))
        }
        entries = working
        persist()
    }

    /// Most recently recorded entry (if any). `nil` when no meets have been
    /// recorded yet; the cold-open mentor surface skips callbacks in that
    /// case so the kid isn't quoted a microbe they've never seen.
    public var mostRecent: MentorRecallEntry? {
        entries.first
    }

    /// Deterministic pick from the buffer — same `rotation` always picks the
    /// same entry. Used by view-local consumers that want fresh-looking
    /// callbacks across visits without storing per-visit state.
    public func entry(for rotation: Int) -> MentorRecallEntry? {
        guard !entries.isEmpty else { return nil }
        let index = abs(rotation) % entries.count
        return entries[index]
    }

    /// Test + Settings-reset hook. Clears all entries + persists the empty
    /// buffer.
    public func clear() {
        entries = []
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: MentorRecallStore.storageKey)
    }
}

/// One recorded "met" entry. Stored on-device only; carries the microbe slug
/// (catalog-derived enum-equivalent string) + the timestamp of the meet so
/// the mentor surface can decide whether to phrase the callback as "earlier
/// today" / "yesterday" / "a while back."
public nonisolated struct MentorRecallEntry: Codable, Sendable, Equatable {
    public let slug: String
    public let lastSeenAt: Date

    public init(slug: String, lastSeenAt: Date) {
        self.slug = slug
        self.lastSeenAt = lastSeenAt
    }
}
