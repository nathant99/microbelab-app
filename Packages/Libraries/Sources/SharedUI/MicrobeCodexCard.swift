import SwiftUI
import Models

/// One codex grid entry. Renders a portrait placeholder + name + role chip +
/// catchphrase. Portrait WebPs land in a follow-up labsmith asset wave per
/// `.claude/rules/forgekit.md` § Asset generation ownership.
///
/// Per `.claude/rules/liquid-glass.md` § per-surface matrix, codex grid cards
/// are **nav-grid cards** (Category C) — tap to drill into the per-microbe
/// detail screen — so they get interactive glass.
public struct MicrobeCodexCard: View {
    public let microbe: MicrobeCharacter
    public let isDiscovered: Bool

    public init(microbe: MicrobeCharacter, isDiscovered: Bool) {
        self.microbe = microbe
        self.isDiscovered = isDiscovered
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            portraitPlaceholder
            HStack(alignment: .firstTextBaseline) {
                Text(isDiscovered ? microbe.displayName : "???")
                    .font(.headline)
                Spacer()
                roleChip
            }
            Text(isDiscovered ? microbe.catchphrase : "Zoom in to meet me.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(microbe.displayName), \(microbe.role.rawValue) microbe")
        .accessibilityHint(isDiscovered ? "Tap to view codex entry" : "Not yet discovered — zoom in to find me")
    }

    private var portraitPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.15))
            Image(systemName: isDiscovered ? "microbe.circle.fill" : "questionmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tint)
        }
        .frame(height: 120)
    }

    private var roleChip: some View {
        Text(microbe.role.rawValue)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(roleColor.opacity(0.2), in: .capsule)
            .foregroundStyle(roleColor)
    }

    private var roleColor: Color {
        switch microbe.role {
        case .beneficial: return .green
        case .neutral: return .gray
        case .opportunistic: return .orange
        case .pathogenic: return .red
        }
    }
}
