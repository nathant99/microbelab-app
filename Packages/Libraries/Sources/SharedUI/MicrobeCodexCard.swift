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
    /// Display names of ecology neighbors surfaced via the
    /// `MicrobeKnowledgeGraph`. When `isDiscovered` AND non-empty, the card
    /// renders a small "Lives near: A, B" caption below the catchphrase.
    /// Kept optional so existing callers + tests don't need to thread the
    /// graph through.
    public let livesNearDisplayNames: [String]

    public init(
        microbe: MicrobeCharacter,
        isDiscovered: Bool,
        livesNearDisplayNames: [String] = []
    ) {
        self.microbe = microbe
        self.isDiscovered = isDiscovered
        self.livesNearDisplayNames = livesNearDisplayNames
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
            if isDiscovered, !livesNearDisplayNames.isEmpty {
                livesNearLine
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isDiscovered ? "Tap to view codex entry" : "Not yet discovered — zoom in to find me")
    }

    private var livesNearLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "link")
                .imageScale(.small)
                .foregroundStyle(.tint)
            Text(verbatim: "Lives near: \(livesNearDisplayNames.joined(separator: ", "))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var accessibilityLabelText: String {
        let base = "\(microbe.displayName), \(microbe.role.rawValue) microbe"
        guard isDiscovered, !livesNearDisplayNames.isEmpty else { return base }
        return "\(base). Lives near \(livesNearDisplayNames.joined(separator: ", "))"
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
