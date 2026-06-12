import Foundation
import Models
import ForgeSpotlight

/// Adapts a `MicrobeCharacter` to ForgeSpotlight's `SpotlightIndexable`
/// protocol so the bundled microbe catalog can be surfaced in iOS Spotlight
/// search. Indexing decisions live in `MicrobeSpotlightIndex` below.
///
/// Per CLAUDE.md § Xcode-managed file safety + `.claude/rules/forgekit.md`
/// § Module Catalog, this is the first MicrobeLab consumer of
/// `ForgeSpotlight` — the module was previously declared-but-unused.
public nonisolated struct MicrobeSpotlightItem: SpotlightIndexable {
    public let microbe: MicrobeCharacter

    public init(microbe: MicrobeCharacter) {
        self.microbe = microbe
    }

    public var spotlightID: String {
        // The deep-link surface uses the slug (stable + URL-safe) so future
        // Universal Links can resolve to `/codex/<slug>`. UUID would be opaque
        // + churn-prone if catalogs ever rehydrate from a remote.
        "microbelab.codex.\(microbe.slug)"
    }

    public var spotlightTitle: String {
        microbe.displayName
    }

    public var spotlightDescription: String {
        // Compose catchphrase + factCard so the Spotlight preview gives both
        // the character voice + the curricular hook. Trimmed at the engine
        // level to fit the Spotlight render envelope.
        "\(microbe.catchphrase) — \(microbe.factCard)"
    }

    public var spotlightKeywords: [String] {
        // Stable enum slugs only (no kid-identifying tokens). Spotlight scores
        // by keyword + title overlap; the kingdom + role + environment keys
        // surface the right microbe when a parent searches "good bacteria gut"
        // or a kid types their guess from memory.
        [
            microbe.slug,
            microbe.displayName,
            microbe.kingdom.rawValue,
            microbe.role.rawValue,
            microbe.preferredEnvironment.rawValue,
        ]
    }
}

/// MainActor `@Observable` wrapper around `ForgeSpotlightIndexer` so SwiftUI
/// surfaces can drive index lifecycle without juggling the actor surface.
///
/// Trauma-informed posture matches `MicrobeCodexView`: the entire bundled
/// catalog is indexed (the codex already shows all 12 cards from launch —
/// locked entries render as "???"), so the Spotlight surface mirrors the
/// codex's discoverability envelope. Searching by microbe name lands the
/// kid on the codex entry; if the microbe is locked the codex still gates
/// the fact card behind discovery.
///
/// Per `.claude/rules/age-assurance.md` § Portfolio Status: no kid data
/// leaves the device; Spotlight's `CSSearchableIndex` stays on-device.
@MainActor
@Observable
public final class MicrobeSpotlightIndex {
    private let indexer: ForgeSpotlightIndexer
    public private(set) var lastIndexedSlugs: [String] = []
    public private(set) var lastIndexError: String?

    public init(domainIdentifier: String = "com.microbelab.codex") {
        self.indexer = ForgeSpotlightIndexer(domainIdentifier: domainIdentifier)
    }

    /// Build SpotlightIndexable adapters for every microbe in the catalog
    /// and submit them to Spotlight. Safe to call repeatedly — the indexer
    /// dedupes by `spotlightID`.
    public func indexCatalog(_ microbes: [MicrobeCharacter]) async {
        let items = microbes.map(MicrobeSpotlightItem.init(microbe:))
        do {
            try await indexer.index(items)
            lastIndexedSlugs = microbes.map(\.slug)
            lastIndexError = nil
            DebugLog.lifecycle("MicrobeSpotlightIndex indexed \(microbes.count) microbes")
        } catch {
            // Don't crash the launch on Spotlight failure — the codex
            // surface still works. Swallow + record per
            // .claude/rules/debug-logging.md § Replace silent try? with
            // logged catches.
            lastIndexError = String(describing: error)
            DebugLog.error("MicrobeSpotlightIndex indexCatalog failed", error: error)
        }
    }

    /// Remove the entire MicrobeLab catalog from Spotlight. Used by Settings
    /// → Privacy "Forget local data" affordance + UI test teardown.
    public func deindexAll() async {
        do {
            try await indexer.deindexDomain("com.microbelab.codex")
            lastIndexedSlugs = []
            lastIndexError = nil
            DebugLog.lifecycle("MicrobeSpotlightIndex domain deindexed")
        } catch {
            lastIndexError = String(describing: error)
            DebugLog.error("MicrobeSpotlightIndex deindexAll failed", error: error)
        }
    }
}
