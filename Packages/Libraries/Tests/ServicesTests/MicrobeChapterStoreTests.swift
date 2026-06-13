import Testing
import Foundation
import Models
@testable import Services

@Suite("MicrobeChapterStore (DN-S chapter loader)")
struct MicrobeChapterStoreTests {

    @Test("Bundled chapters cover every canonical cast member")
    func bundledChaptersCoverCanonicalCast() {
        let store = MicrobeChapterStore()
        for slug in MicrobeChapterStore.canonicalSlugs {
            #expect(store.chapter(for: slug) != nil, "Missing chapter for canonical slug \(slug)")
        }
    }

    @Test("Codex-supporting cast slugs without authored chapters return nil")
    func codexSupportingCastReturnsNil() {
        let store = MicrobeChapterStore()
        let codexOnlySlugs = ["bifido", "akker", "strep", "coli", "rhino", "deino"]
        for slug in codexOnlySlugs {
            #expect(
                store.chapter(for: slug) == nil,
                "Codex-supporting microbe \(slug) should not have an authored chapter yet"
            )
        }
    }

    @Test("Lacto chapter parses title from H1")
    func lactoChapterTitle() {
        let store = MicrobeChapterStore()
        let chapter = store.chapter(for: "lacto")
        #expect(chapter != nil)
        #expect(chapter?.title.hasPrefix("Chapter 1") == true)
    }

    @Test("Parse strips YAML front-matter")
    func parseStripsFrontMatter() {
        let contents = """
        ---
        character: TestMicrobe
        register: test
        ---

        # Chapter 1 — TestMicrobe and the Story

        Body line one.
        Body line two.
        """
        let chapter = MicrobeChapterStore.parse(slug: "test", contents: contents)
        #expect(chapter != nil)
        #expect(chapter?.title == "Chapter 1 — TestMicrobe and the Story")
        #expect(chapter?.body.contains("character: TestMicrobe") == false)
        #expect(chapter?.body.contains("Body line one") == true)
    }

    @Test("Parse rejects empty body")
    func parseRejectsEmptyBody() {
        let contents = """
        ---
        character: TestMicrobe
        ---
        """
        let chapter = MicrobeChapterStore.parse(slug: "test", contents: contents)
        #expect(chapter == nil)
    }

    @Test("Parse derives reading minutes at 200wpm")
    func parseReadingMinutesAt200wpm() {
        let body = Array(repeating: "word", count: 400).joined(separator: " ")
        let contents = "# Chapter 1 — Test\n\n\(body)"
        let chapter = MicrobeChapterStore.parse(slug: "test", contents: contents)
        #expect(chapter != nil)
        // 400 words / 200wpm = 2 min.
        #expect(chapter?.estimatedReadingMinutes == 2)
    }

    @Test("Parse falls back to default title when H1 missing")
    func parseFallsBackToDefaultTitle() {
        let contents = """
        ---
        character: TestMicrobe
        ---

        Just body, no heading.
        """
        let chapter = MicrobeChapterStore.parse(slug: "test", contents: contents)
        #expect(chapter?.title == "Chapter 1")
    }

    @Test("availableSlugs returns the bundled set")
    func availableSlugsReturnsBundledSet() {
        let store = MicrobeChapterStore()
        let expected = Set(MicrobeChapterStore.canonicalSlugs)
        #expect(store.availableSlugs == expected)
    }

    @Test("Injected chapters override bundled lookup")
    func injectedChaptersOverrideBundledLookup() {
        let fixture = MicrobeChapter(
            slug: "fixture",
            title: "Test",
            body: "Body",
            estimatedReadingMinutes: 1
        )
        let store = MicrobeChapterStore(chapters: [fixture])
        #expect(store.chapter(for: "fixture") != nil)
        // None of the bundled canonical slugs should be present when we
        // pass an explicit fixture list.
        #expect(store.chapter(for: "lacto") == nil)
    }

    @Test("Resource bundle is exposed for ChapterPortraitView consumers")
    func resourceBundleExposed() {
        // Just verify the static is accessible — Bundle is opaque, but
        // having a non-default-arg public accessor is the surface AppFeature
        // depends on.
        let bundle = MicrobeChapterStore.resourcesBundle
        // Smoke test: at least one canonical chapter is reachable in the
        // bundle root (SPM's `.process` flattens unknown file types).
        let lactoURL = bundle.url(forResource: "lacto", withExtension: "md")
        #expect(lactoURL != nil)
    }

    @Test("Reading minutes is always at least 1 even for tiny chapters")
    func readingMinutesAtLeastOne() {
        let contents = "# Chapter 1 — Short\n\nTwo words."
        let chapter = MicrobeChapterStore.parse(slug: "short", contents: contents)
        #expect(chapter?.estimatedReadingMinutes == 1)
    }
}
