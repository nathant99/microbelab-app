import SwiftUI
import Models
import Services
import SharedUI
import ForgeIllustrations

/// Reader sheet for a microbe's DN-S chapter. Surfaces the chapter title
/// + opener illustration (resolved via `ForgeIllustrations.ChapterPortraitView`)
/// + the markdown body in a kid-readable reading column.
///
/// Trauma-informed posture: the sheet is opt-in — kids only see it after
/// discovering the microbe (the codex card tap surfaces the affordance
/// only on discovered cards). The reading register matches the chapter
/// source (ages 9-14 per the DN-S front-matter). Off-ramp is the
/// standard system sheet swipe-down + the explicit Done toolbar button.
///
/// **Cast-portrait anchor row** (optional, post PR #200 portrait seam):
/// when `microbe` is non-nil, a compact `SharedUI.MicrobePortraitView`
/// row surfaces above the chapter title — anchors the chapter visually
/// to the cast member it's about. Default `microbe == nil` matches the
/// previous shape so existing call sites that only pass display name
/// still render cleanly (the chapter opener illustration carries the
/// visual register alone). Sheet only opens on discovered cards per
/// the codex tap gate, so the discovered branch is the default truth
/// at every consumer call site.
public struct ChapterReaderSheet: View {
    public let chapter: MicrobeChapter
    public let microbeDisplayName: String
    public let microbe: MicrobeCharacter?
    public let isMicrobeDiscovered: Bool
    public let bundle: Bundle
    @Environment(\.dismiss) private var dismiss

    public init(
        chapter: MicrobeChapter,
        microbeDisplayName: String,
        microbe: MicrobeCharacter? = nil,
        isMicrobeDiscovered: Bool = true,
        bundle: Bundle = .main
    ) {
        self.chapter = chapter
        self.microbeDisplayName = microbeDisplayName
        self.microbe = microbe
        self.isMicrobeDiscovered = isMicrobeDiscovered
        self.bundle = bundle
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ChapterPortraitView(
                        slug: chapter.slug,
                        variant: .opener,
                        altText: "Chapter opener illustration for \(microbeDisplayName)",
                        bundle: bundle
                    )
                    .frame(maxWidth: 512)
                    .frame(maxWidth: .infinity, alignment: .center)

                    if let microbe {
                        HStack(spacing: 12) {
                            MicrobePortraitView(
                                microbe: microbe,
                                isDiscovered: isMicrobeDiscovered,
                                bundle: bundle
                            )
                            .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("About this microbe")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(verbatim: microbe.displayName)
                                    .font(.headline)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Chapter about \(microbe.displayName)")
                    }

                    Text(verbatim: chapter.title)
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)

                    Label(
                        "\(chapter.estimatedReadingMinutes) min read",
                        systemImage: "book.closed"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("About \(chapter.estimatedReadingMinutes) minutes to read")

                    Text(.init(chapter.body))
                        .font(.body)
                        .lineSpacing(4)
                        .frame(maxWidth: 640, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle(Text(verbatim: microbeDisplayName))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
