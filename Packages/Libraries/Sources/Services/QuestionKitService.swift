import Foundation
import Models

/// Loads bundled question kit JSON files from `Bundle.module`. Phase 1 ships
/// kit 01 (microbiology basics); kits 02-04 land in Phase 1 follow-ups per
/// `Docs/FEATURE_PLAN.md` § Gamification.
public nonisolated struct QuestionKitService: Sendable {
    public enum LoadError: Error, Sendable {
        case resourceMissing(slug: String)
        case decodingFailed(slug: String, message: String)
    }

    /// Slugs of every kit bundled at app boot. Order is canonical kit order
    /// — used by the UI to drive the kit-progress strip.
    public static let phase1KitSlugs: [String] = [
        "microbiology-basics"
    ]

    public init() {}

    public func loadKit(slug: String) -> Result<QuestionKit, LoadError> {
        // Filename convention: `kit_<NN>_<slug-with-underscores>.json`. The
        // index isn't load-bearing — we resolve by content-search rather than
        // assuming a particular index.
        let normalizedSlug = slug.replacingOccurrences(of: "-", with: "_")
        guard let url = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: nil)?
            .first(where: { $0.lastPathComponent.contains(normalizedSlug) }) else {
            return .failure(.resourceMissing(slug: slug))
        }
        do {
            let data = try Data(contentsOf: url)
            let kit = try JSONDecoder().decode(QuestionKit.self, from: data)
            return .success(kit)
        } catch {
            return .failure(.decodingFailed(slug: slug, message: String(describing: error)))
        }
    }

    /// Convenience: load every Phase-1 kit slug, dropping kits that fail to
    /// load (with an `error` log seam). Callers MUST handle the empty case
    /// since the UI shouldn't surface a blank list.
    public func loadAllPhase1Kits() -> [QuestionKit] {
        Self.phase1KitSlugs.compactMap { slug in
            switch loadKit(slug: slug) {
            case .success(let kit): return kit
            case .failure(let error):
                DebugLog.data("QuestionKitService.loadAllPhase1Kits failed for \(slug): \(error)")
                return nil
            }
        }
    }
}
