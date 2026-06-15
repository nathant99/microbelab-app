import Foundation
import Models

/// Loads bundled question kit JSON files from `Bundle.module`. Phase 1 ships
/// kits 01-04 (microbiology basics / microbiome / immune defense / beneficial
/// microbes); Phase 2 ships kits 05-08 (adaptive immunity / oral biome / skin
/// biome / soil biome) per `Docs/FEATURE_PLAN.md` § Phase 2. Kit 05
/// (adaptive-immunity) shipped the eighteenth-pass auto-cycle round (PR #120)
/// alongside the BCellAntibody surface (PR #105) + AdaptiveImmunityUnlock
/// (PR #108) + mentor cues (PR #111). Kits 06 (oral) + 07 (skin) + 08 (soil)
/// ship the nineteenth-pass auto-cycle round (2026-06-15) ahead of the
/// per-ecology microbiome scenes so the kit-progress strip can surface them
/// the moment they land.
public nonisolated struct QuestionKitService: Sendable {
    public enum LoadError: Error, Sendable {
        case resourceMissing(slug: String)
        case decodingFailed(slug: String, message: String)
    }

    /// Slugs of every Phase-1 kit bundled at app boot. Order is canonical kit
    /// order — used by the UI to drive the kit-progress strip.
    public static let phase1KitSlugs: [String] = [
        "microbiology-basics",
        "microbiome",
        "immune-defense",
        "beneficial-microbes"
    ]

    /// Slugs of every Phase-2 kit bundled to date. Kit 05 ships alongside the
    /// adaptive-immunity gameplay surface (`BCellAntibodyMatchScene` +
    /// `AdaptiveImmunityUnlock`). Kits 06-08 (oral / skin / soil microbiome)
    /// ship ahead of the corresponding microbiome scenes so the kit-progress
    /// strip surfaces the full Phase 2 set; per-ecology scene authoring
    /// follows as separate FEATURE_PLAN items. Order is canonical kit order.
    public static let phase2KitSlugs: [String] = [
        "adaptive-immunity",
        "oral-microbiome",
        "skin-microbiome",
        "soil-microbiome"
    ]

    /// Convenience union: every shipped kit slug in canonical order. Used by
    /// new UI surfaces that span both phases (e.g., the Codex → Quizzes Menu).
    public static var allKitSlugs: [String] {
        phase1KitSlugs + phase2KitSlugs
    }

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

    /// Convenience: load every Phase-2 kit slug shipped to date, same
    /// drop-on-error semantics as `loadAllPhase1Kits()`. Returns an empty
    /// array if no Phase-2 kits have shipped yet.
    public func loadAllPhase2Kits() -> [QuestionKit] {
        Self.phase2KitSlugs.compactMap { slug in
            switch loadKit(slug: slug) {
            case .success(let kit): return kit
            case .failure(let error):
                DebugLog.data("QuestionKitService.loadAllPhase2Kits failed for \(slug): \(error)")
                return nil
            }
        }
    }
}
