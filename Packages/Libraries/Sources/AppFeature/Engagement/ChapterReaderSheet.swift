import SwiftUI
import Models
import Services
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
public struct ChapterReaderSheet: View {
    public let chapter: MicrobeChapter
    public let microbeDisplayName: String
    public let bundle: Bundle
    @Environment(\.dismiss) private var dismiss

    public init(
        chapter: MicrobeChapter,
        microbeDisplayName: String,
        bundle: Bundle = .main
    ) {
        self.chapter = chapter
        self.microbeDisplayName = microbeDisplayName
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
