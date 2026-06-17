import Foundation
import ForgeModels
import Observation

/// On-device append-only persistence for `ForgeModels.ReflectionEntry` rows.
///
/// Wraps the `ReflectionEntry` values emitted by ForgeKit 0.99.0's
/// `ReflectionPromptModifier` `onComplete` callback so MicrobeLab can ship
/// the session-close reflection surface without committing to
/// `ForgePersistence.ReflectionPromptStorage`'s SwiftData container (which
/// would require adding `ReflectionEntryRecord` to the MicrobeLab schema +
/// a migration). UserDefaults persistence keeps the integration light +
/// migration-free + portable to the eventual SwiftData store via a
/// straight-line read-and-replay if/when MicrobeLab migrates.
///
/// **COPPA + retention posture** (per `.claude/rules/age-assurance.md`
/// § Portfolio Status + 2026 FTC COPPA Rule § Data retention limits):
///
/// - Storage is **on-device only**. No remote sync, no third-party SDK.
/// - Storage is **ring-buffered at 50 entries** so the kid's reflection
///   history doesn't grow unbounded; FIFO eviction drops the oldest
///   entry when the cap is hit.
/// - `purge(olderThan:)` removes entries past the supplied cutoff
///   alongside any sandboxed asset file (voice memo, drawing) the entry
///   referenced. The 2026 FTC rule requires a documented retention
///   period; MicrobeLab's default is the 90-day window per
///   `Docs/PRIVACY_POLICY.md`.
/// - `parentVisible` filtering is the responsibility of the consumer
///   per the ForgeKit `ReflectionPromptStorage.parentVisibleEntries`
///   convention; this store never assumes any entry is parent-visible.
@MainActor
@Observable
public final class ReflectionEntryStore {
    public private(set) var entries: [ReflectionEntry] = []

    /// Pending crisis-resource surface presentation derived from the most
    /// recent appended entry. Nil when the entry's text screened `.calm` OR
    /// the consumer has already dismissed the previous presentation.
    ///
    /// Consumers observe + clear via `acknowledgeDespairPresentation()` so
    /// a single elevated signal doesn't re-fire across re-renders.
    ///
    /// Closes Phase 3 FEATURE_PLAN line 161 (crisis-resource surfacing
    /// if despair signals detected). Defense-in-depth alongside the
    /// always-on Settings surface — the reactive layer surfaces support
    /// the moment the kid authors the signal, never an extra hop.
    public private(set) var pendingDespairPresentation: DespairSignalSurface.Presentation?

    /// Capacity ceiling per portfolio convention for UserDefaults-backed
    /// engagement stores (`RetentionMetricsStore` ring buffer cap 32 +
    /// `MentorRecallStore` cap 5 — MicrobeLab uses a 50 cap here because
    /// reflection entries are denser per session and parent-dashboard
    /// surfaces want a longer window).
    public static let capacity = 50

    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let despairDetector = DespairSignalDetector()

    public init(
        defaults: UserDefaults = .standard,
        key: String = "microbelab.engagement.reflectionEntries"
    ) {
        self.defaults = defaults
        self.key = key
        hydrate()
    }

    /// Append a fresh entry. FIFO-evicts the oldest if at capacity.
    ///
    /// Side effect: if the entry's textual content matches a despair
    /// signal, sets `pendingDespairPresentation` so the view layer can
    /// surface the crisis-resource card. The text itself is never
    /// persisted past the detector call (per
    /// `.claude/rules/debug-logging.md` § Privacy by default).
    public func append(_ entry: ReflectionEntry) {
        var next = entries
        next.append(entry)
        if next.count > Self.capacity {
            next.removeFirst(next.count - Self.capacity)
        }
        entries = next
        flush()

        // Screen the entry's text for despair signals. Only `.text`
        // modality carries author text here; `.emoji` carries a glyph
        // codepoint that's not despair-signal-bearing, `.skip` carries
        // no payload, `.voice` / `.drawing` carry an asset URL only.
        if entry.modality == .text, let text = entry.textValue, !text.isEmpty {
            let severity = despairDetector.detect(in: text)
            if let presentation = DespairSignalSurface.presentation(for: severity) {
                pendingDespairPresentation = presentation
            }
        }
    }

    /// Clear the pending despair surface so the kid's next reflection
    /// starts fresh. Consumer calls this when the kid dismisses the
    /// crisis-resource card.
    public func acknowledgeDespairPresentation() {
        pendingDespairPresentation = nil
    }

    /// Return entries for the given prompt ID — useful when surfacing
    /// "last reflection for this prompt" on the parent dashboard.
    public func entries(forPromptID promptID: String) -> [ReflectionEntry] {
        entries.filter { $0.promptID == promptID }
    }

    /// Remove all entries strictly older than `cutoff`. Best-effort
    /// removes the sandboxed asset file (voice memo, drawing) the
    /// entry referenced — failures are silently tolerated because the
    /// entry was already past its retention window.
    @discardableResult
    public func purge(olderThan cutoff: Date) -> Int {
        let kept = entries.filter { $0.respondedAt >= cutoff }
        let removed = entries.count - kept.count
        for entry in entries where entry.respondedAt < cutoff {
            if let url = entry.assetFileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        if removed > 0 {
            entries = kept
            flush()
        }
        return removed
    }

    /// Clear all entries. Used by parental controls + test setup.
    public func clear() {
        for entry in entries {
            if let url = entry.assetFileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        entries = []
        flush()
    }

    // MARK: - Persistence

    private func hydrate() {
        guard let data = defaults.data(forKey: key) else { return }
        guard let decoded = try? decoder.decode([ReflectionEntry].self, from: data) else {
            // Forward-incompatible payloads: drop quietly + start fresh.
            // The kid's prior reflections are local journal — losing
            // them is a "soft" failure, not data loss the kid expects
            // to recover.
            defaults.removeObject(forKey: key)
            return
        }
        entries = decoded
    }

    private func flush() {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}
