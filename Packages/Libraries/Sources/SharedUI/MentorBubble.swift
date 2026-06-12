import SwiftUI

/// Cilia mentor speech bubble. Surfaces static catchphrases + curriculum
/// fact cards from `AIMentor.VeeMentor`. Real FoundationModels-driven
/// Socratic dialogue lands in a follow-up PR.
public struct MentorBubble: View {
    public let mentorName: String
    public let message: String

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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mentorName) says: \(message)")
    }
}
