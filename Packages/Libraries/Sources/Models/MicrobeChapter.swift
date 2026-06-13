import Foundation

/// One DN-S chapter for a named microbe. Carries the parsed front-matter
/// metadata + the markdown body so the in-app reader can surface the
/// chapter to discovered microbes without re-parsing on every read.
///
/// Authored against the DN-S chapter shape codified in
/// `Docs/dn-s/chapters/<slug>.md` (front-matter + markdown body).
public nonisolated struct MicrobeChapter: Sendable, Equatable, Hashable, Identifiable, Codable {
    /// Stable kebab-case slug matching `MicrobeCharacter.slug` + the chapter
    /// filename root (`lacto.md` → `"lacto"`).
    public let slug: String

    /// Display title pulled from the chapter's first H1 (`# Chapter 1 — ...`).
    /// Falls back to `"Chapter 1"` when the H1 is missing.
    public let title: String

    /// Body markdown with the YAML front-matter stripped. Renders directly
    /// in the chapter-reader sheet via SwiftUI `Text(LocalizedStringKey:)`
    /// markdown parsing.
    public let body: String

    /// Estimated reading minutes for the body — derived from `wordCount`
    /// using the canonical 200wpm middle-grade reading rate.
    public let estimatedReadingMinutes: Int

    public var id: String { slug }

    public init(slug: String, title: String, body: String, estimatedReadingMinutes: Int) {
        self.slug = slug
        self.title = title
        self.body = body
        self.estimatedReadingMinutes = estimatedReadingMinutes
    }
}
