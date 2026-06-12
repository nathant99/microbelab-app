import SwiftUI
import Models

/// Microscope tier-badge + magnification HUD overlay surfaced above the
/// `SpriteView` host. Per `.claude/rules/spritekit.md` § SpriteView layout
/// cascade the HUD lives in a `safeAreaInset` so the underlying scene reserves
/// space rather than rendering under the chrome.
///
/// The row of `TierBadge`s is the tier selector; the active tier displays its
/// magnification factor in a dedicated chip beneath it. Liquid Glass on the
/// chip is OK per `.claude/rules/liquid-glass.md` § Category B — interactive
/// + nav controls.
public struct MicroscopeHUD: View {
    public let currentTier: ZoomTier
    public let onSnap: (ZoomTier) -> Void

    public init(currentTier: ZoomTier, onSnap: @escaping (ZoomTier) -> Void) {
        self.currentTier = currentTier
        self.onSnap = onSnap
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(ZoomTier.allCases, id: \.self) { tier in
                    TierBadge(tier: tier, isActive: tier == currentTier) {
                        onSnap(tier)
                    }
                }
            }
            magnificationChip
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Microscope HUD; current tier \(currentTier.displayLabel)")
    }

    private var magnificationChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "scope")
                .imageScale(.small)
            Text(verbatim: currentTier.displayLabel)
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("MicroscopeHUD — light tier") {
    MicroscopeHUD(currentTier: .light) { _ in }
        .padding()
        .background(Color.black.opacity(0.4))
}

#Preview("MicroscopeHUD — electron tier") {
    MicroscopeHUD(currentTier: .electron) { _ in }
        .padding()
        .background(Color.black.opacity(0.4))
}
#endif
