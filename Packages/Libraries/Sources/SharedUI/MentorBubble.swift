import SwiftUI

/// Cilia mentor speech bubble. Surfaces static catchphrases + curriculum
/// fact cards from `AIMentor.VeeMentor`. Real FoundationModels-driven
/// Socratic dialogue lands in a follow-up PR.
///
/// Honors `@Environment(\.accessibilityReduceTransparency)` by swapping
/// `.thinMaterial` for a solid neutral fill. The app-level
/// `forceReduceTransparency` toggle layers on top of the system env in
/// `AppRootView`; the bubble itself only needs to read the resolved env.
public struct MentorBubble: View {
    public let mentorName: String
    public let message: String

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(mentorName: String = "Cilia", message: String) {
        self.mentorName = mentorName
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bubble.left.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: mentorName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
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
        .accessibilityLabel("\(mentorName) says: \(message)")
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
