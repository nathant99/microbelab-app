import SwiftUI
import Models

/// Microscope tier badge surfaced in the SwiftUI HUD overlay above the
/// microscope `SpriteView`. Per `.claude/rules/liquid-glass.md` § Quick
/// Reference — interactive controls (Category B) use glass; we tap to snap
/// to a tier so the badge IS interactive.
public struct TierBadge: View {
    public let tier: ZoomTier
    public let isActive: Bool
    public let onTap: () -> Void

    public init(tier: ZoomTier, isActive: Bool, onTap: @escaping () -> Void) {
        self.tier = tier
        self.isActive = isActive
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(verbatim: tier.displayLabel)
                    .font(.headline.monospacedDigit())
                Text(badgeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
        .opacity(isActive ? 1.0 : 0.6)
        .accessibilityHint("Tap to snap to \(tier.displayLabel) microscope tier")
    }

    private var badgeLabel: String {
        switch tier {
        case .unaided: return "Naked eye"
        case .light: return "Light"
        case .fluorescence: return "Fluor"
        case .electron: return "Electron"
        }
    }
}
