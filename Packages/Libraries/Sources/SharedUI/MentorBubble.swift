import SwiftUI
import Models

/// Cilia mentor speech bubble. Surfaces static catchphrases + curriculum
/// fact cards from `AIMentor.VeeMentor`. Real FoundationModels-driven
/// Socratic dialogue lands in a follow-up PR.
///
/// Honors `@Environment(\.accessibilityReduceTransparency)` by swapping
/// `.thinMaterial` for a solid neutral fill. The app-level
/// `forceReduceTransparency` toggle layers on top of the system env in
/// `AppRootView`; the bubble itself only needs to read the resolved env.
///
/// **Featured-microbe turn-prefix** (optional, post PR #200 portrait seam):
/// when `featuredMicrobe` is non-nil, the bubble surfaces a compact
/// `MicrobePortraitView` to the left of the speech-bubble glyph + an
/// "About \(displayName)" caption under the mentor name. The default
/// `featuredMicrobe == nil` matches every existing call site so no
/// caller migration is required. The seam is the consumer-side hook
/// the future cast-voicing UI (DN-S Phase 1 Move D) plugs into.
public struct MentorBubble: View {
    public let mentorName: String
    public let message: String
    public let featuredMicrobe: MicrobeCharacter?
    public let featuredMicrobeIsDiscovered: Bool
    public let portraitBundle: Bundle

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        mentorName: String = "Cilia",
        message: String,
        featuredMicrobe: MicrobeCharacter? = nil,
        featuredMicrobeIsDiscovered: Bool = true,
        portraitBundle: Bundle = .main
    ) {
        self.mentorName = mentorName
        self.message = message
        self.featuredMicrobe = featuredMicrobe
        self.featuredMicrobeIsDiscovered = featuredMicrobeIsDiscovered
        self.portraitBundle = portraitBundle
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let microbe = featuredMicrobe {
                MicrobePortraitView(
                    microbe: microbe,
                    isDiscovered: featuredMicrobeIsDiscovered,
                    bundle: portraitBundle
                )
                .frame(width: 40, height: 40)
                .padding(.top, 2)
            } else {
                Image(systemName: "bubble.left.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: mentorName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                if let microbe = featuredMicrobe {
                    Text("About \(microbe.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bubbleBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        if let microbe = featuredMicrobe {
            return "\(mentorName) about \(microbe.displayName): \(message)"
        }
        return "\(mentorName) says: \(message)"
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: 14)
                .fill(SolidReduceTransparencyFill.color)
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
        }
    }
}

/// Cross-platform solid-fill replacement for `.thinMaterial` / `.glassEffect`
/// surfaces when Reduce Transparency is active. Adapts to light/dark mode
/// via `Color.primary` opacity rather than picking a UIKit-only system
/// color (so the package can compile for both iOS + macOS targets per
/// `Package.swift`).
enum SolidReduceTransparencyFill {
    static let color: Color = Color.primary.opacity(0.08)
}
