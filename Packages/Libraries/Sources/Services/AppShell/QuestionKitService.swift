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

    /// Slugs of every Phase-3 kit bundled to date. Kits 09-12 ship as
    /// `.draftAwaitingReview` placeholders until external SAMHSA TIP 57
    /// register reviewer signoff lands per ADR-016. The bundled JSON is
    /// structural scaffolding — `loadAllPhase3Kits()` filters out any kit
    /// whose `authoring != .reviewerSignedOff`, so draft content NEVER
    /// surfaces to a kid. Order is canonical kit order.
    public static let phase3KitSlugs: [String] = [
        "vaccines",
        "herd-immunity",
        "hygiene",
        "public-health"
    ]

    /// Slugs of every Phase-4 kit bundled to date. Kits 13-16 ship as
    /// `.draftAwaitingReview` placeholders mirroring the Phase 3 pattern.
    /// Kit 14 (global microbiome) additionally cites the cultural-respect
    /// gate from `.claude/rules/distributed-narrative.md` § cultural-sensitivity
    /// gates because Yellowstone TEK + deep-sea exploration framing falls under
    /// the Indigenous-knowledge-credit register. `loadAllPhase4Kits()` filters
    /// out any kit whose `authoring != .reviewerSignedOff`, so draft content
    /// NEVER surfaces to a kid. Order is canonical kit order.
    public static let phase4KitSlugs: [String] = [
        "extremophiles",
        "global-microbiome",
        "microbiome-research",
        "synthesis"
    ]

    /// Convenience union: every shipped kit slug in canonical order. Used by
    /// new UI surfaces that span all phases (e.g., the Codex → Quizzes Menu).
    /// Note: this returns SLUGS regardless of authoring state — consumer
    /// surfaces that should hide draft content must call
    /// `loadAllShippedKits()` instead so unreviewed kits get filtered out.
    public static var allKitSlugs: [String] {
        phase1KitSlugs + phase2KitSlugs + phase3KitSlugs + phase4KitSlugs
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

    /// Convenience: load every Phase-3 kit slug that has reached
    /// reviewer-signoff. Kits still in `.placeholder` or
    /// `.draftAwaitingReview` are silently dropped so unreviewed content
    /// NEVER surfaces to a kid. Same drop-on-error semantics as
    /// `loadAllPhase1Kits()`. Returns an empty array until the first Phase-3
    /// kit ships reviewer-signed-off (this is the canonical state at the
    /// scaffold round).
    public func loadAllPhase3Kits() -> [QuestionKit] {
        Self.phase3KitSlugs.compactMap { slug in
            switch loadKit(slug: slug) {
            case .success(let kit):
                guard kit.authoring == .reviewerSignedOff else { return nil }
                return kit
            case .failure(let error):
                DebugLog.data("QuestionKitService.loadAllPhase3Kits failed for \(slug): \(error)")
                return nil
            }
        }
    }

    /// Convenience: load every Phase-4 kit slug that has reached
    /// reviewer-signoff. Kits still in `.placeholder` or
    /// `.draftAwaitingReview` are silently dropped so unreviewed content
    /// NEVER surfaces to a kid. Same drop-on-error semantics as
    /// `loadAllPhase1Kits()`. Returns an empty array until the first Phase-4
    /// kit ships reviewer-signed-off (this is the canonical state at the
    /// scaffold round; mirrors `loadAllPhase3Kits()` exactly).
    public func loadAllPhase4Kits() -> [QuestionKit] {
        Self.phase4KitSlugs.compactMap { slug in
            switch loadKit(slug: slug) {
            case .success(let kit):
                guard kit.authoring == .reviewerSignedOff else { return nil }
                return kit
            case .failure(let error):
                DebugLog.data("QuestionKitService.loadAllPhase4Kits failed for \(slug): \(error)")
                return nil
            }
        }
    }

    /// Convenience: load every shipped kit across all phases, filtering out
    /// Phase-3 + Phase-4 kits that are still in placeholder / draft
    /// authoring. This is the canonical accessor for UI surfaces that span
    /// phases (Codex → Quizzes Menu, ProgressReport snapshots).
    public func loadAllShippedKits() -> [QuestionKit] {
        loadAllPhase1Kits() + loadAllPhase2Kits() + loadAllPhase3Kits() + loadAllPhase4Kits()
    }
}
