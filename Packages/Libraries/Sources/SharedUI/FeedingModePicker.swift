import SwiftUI
import Models

/// Feeding-mode picker for the microbiome puzzle. 4-pill segmented control
/// per `.claude/rules/liquid-glass.md` § Interactive controls (Category B).
public struct FeedingModePicker: View {
    public let selected: FeedingMode
    public let onSelect: (FeedingMode) -> Void

    public init(selected: FeedingMode, onSelect: @escaping (FeedingMode) -> Void) {
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(FeedingMode.allCases, id: \.self) { mode in
                Button(action: { onSelect(mode) }) {
                    Text(label(for: mode))
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.glass)
                .opacity(selected == mode ? 1.0 : 0.55)
                .accessibilityLabel("Feeding mode: \(label(for: mode))")
                .accessibilityHint(selected == mode ? "Currently selected" : "Tap to switch feeding mode")
            }
        }
    }

    private func label(for mode: FeedingMode) -> String {
        switch mode {
        case .fiber: return "Fiber"
        case .sugar: return "Sugar"
        case .balanced: return "Balanced"
        case .none: return "Empty"
        }
    }
}
