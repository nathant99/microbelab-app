import Foundation
import Models

/// Loads DN-S chapter markdown bundled under `Services/Resources/Chapters/<slug>.md`
/// + exposes a slug-indexed lookup for the kid-facing reader sheet.
///
/// Chapters are bundled at SPM build time (`Bundle.module`); the store
/// caches parsed `MicrobeChapter` values keyed by slug so codex taps don't
/// re-parse the markdown on every open. Microbes without a chapter file
/// return `nil` — the reader UI gates on presence so codex-supporting
/// microbes without DN-S content show no orphan "Read story" affordance.
public nonisolated struct MicrobeChapterStore: Sendable {
    private let chapters: [String: MicrobeChapter]

    public static let canonicalSlugs: [String] = [
        "lacto", "yeast", "photo", "net", "spore", "guard",
    ]

    /// SPM resource bundle that ships the chapter markdown + (eventually)
    /// chapter illustrations. Exposed publicly so AppFeature-side
    /// consumers can pass it to `ForgeIllustrations.ChapterPortraitView`
    /// without needing direct access to the Services target's internal
    /// `Bundle.module`.
    public static let resourcesBundle: Bundle = .module

    public init(chapters: [MicrobeChapter]? = nil) {
        let source = chapters ?? MicrobeChapterStore.loadBundled()
        var map: [String: MicrobeChapter] = [:]
        for chapter in source {
            map[chapter.slug] = chapter
        }
        self.chapters = map
    }

    /// Returns the chapter for the given microbe slug, or `nil` when the
    /// microbe doesn't yet have an authored chapter (codex-supporting
    /// cast members; future microbes added before their DN-S round).
    public func chapter(for slug: String) -> MicrobeChapter? {
        chapters[slug]
    }

    /// Stable kebab-case slugs present in the store. Used by tests + the
    /// codex view to filter the cast to "has chapter" / "no chapter" rows.
    public var availableSlugs: Set<String> { Set(chapters.keys) }

    /// Loads every canonical-slug `<slug>.md` from `Bundle.module`. SPM's
    /// `.process("Resources")` rule flattens unknown file types to the
    /// bundle root, so the loader looks up each canonical slug by name
    /// rather than crawling a subdirectory. Each file is parsed via
    /// `Self.parse(slug:contents:)` + skipped on parse failure rather than
    /// throwing — a malformed chapter file should never crash the codex.
    /// Pass a custom bundle for tests that need to inject fixture chapters.
    public static func loadBundled(bundle: Bundle? = nil) -> [MicrobeChapter] {
        let resolved = bundle ?? Bundle.module
        var chapters: [MicrobeChapter] = []
        for slug in canonicalSlugs {
            guard let url = resolved.url(forResource: slug, withExtension: "md") else {
                continue
            }
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }
            if let chapter = parse(slug: slug, contents: contents) {
                chapters.append(chapter)
            }
        }
        return chapters.sorted { $0.slug < $1.slug }
    }

    /// Pure parser exposed for tests. Strips the YAML front-matter (lines
    /// between two `---` delimiters), captures the first H1 as the title,
    /// + counts whitespace-separated words in the body to derive
    /// `estimatedReadingMinutes` at the canonical 200wpm middle-grade rate.
    public static func parse(slug: String, contents: String) -> MicrobeChapter? {
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        var bodyStart = 0
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
            // Skip front-matter block — find closing `---`.
            for index in 1..<lines.count {
                if lines[index].trimmingCharacters(in: .whitespaces) == "---" {
                    bodyStart = index + 1
                    break
                }
            }
        }
        guard bodyStart < lines.count else { return nil }

        var title = "Chapter 1"
        var bodyLines: [String] = []
        var foundTitle = false
        for index in bodyStart..<lines.count {
            let line = String(lines[index])
            if !foundTitle, line.hasPrefix("# ") {
                title = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                foundTitle = true
                continue
            }
            bodyLines.append(line)
        }

        let body = bodyLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return nil }

        let wordCount = body
            .split(whereSeparator: { $0.isWhitespace })
            .count
        let minutes = max(1, Int((Double(wordCount) / 200.0).rounded(.up)))

        return MicrobeChapter(
            slug: slug,
            title: title,
            body: body,
            estimatedReadingMinutes: minutes
        )
    }
}
