import Foundation
import Models

/// View-local state machine driving the microscope-zoom UX.
///
/// Per `.claude/rules/state-machines.md` § `*Machine` Structs. Pure value type;
/// `nonisolated` so it can be carried across MainActor boundaries (e.g. into
/// SpriteKit scenes when staging the LOD swap).
///
/// State carries:
/// - the current `ZoomTier`
/// - a continuous in-tier scrub value (0 ... 1) for pinch-snap UX
/// - a `pendingTransition` marker the scene reads to decide when to swap LOD
public nonisolated struct ZoomMachine: Sendable, Equatable {
    public var currentTier: ZoomTier
    /// Fractional zoom within the current tier — 0 at the lower boundary,
    /// 1 at the upper boundary. The scene uses this for smooth camera scaling
    /// between LOD swaps.
    public var inTierProgress: Double
    public var pendingTransition: PendingTransition?

    public nonisolated enum PendingTransition: Sendable, Equatable {
        case zoomingIn(from: ZoomTier, to: ZoomTier)
        case zoomingOut(from: ZoomTier, to: ZoomTier)
    }

    public init(
        currentTier: ZoomTier = .unaided,
        inTierProgress: Double = 0,
        pendingTransition: PendingTransition? = nil
    ) {
        self.currentTier = currentTier
        self.inTierProgress = inTierProgress.clamped(to: 0...1)
        self.pendingTransition = pendingTransition
    }

    /// Reset to baseline naked-eye state.
    public mutating func reset() {
        self = ZoomMachine()
    }

    /// Apply a pinch delta (positive = zoom in, negative = zoom out). When the
    /// in-tier progress crosses a boundary the machine populates
    /// `pendingTransition` for the scene to react to.
    public mutating func applyPinch(delta: Double) {
        let newProgress = inTierProgress + delta
        if newProgress > 1, let next = currentTier.next {
            pendingTransition = .zoomingIn(from: currentTier, to: next)
            currentTier = next
            inTierProgress = 0
        } else if newProgress < 0, let previous = currentTier.previous {
            pendingTransition = .zoomingOut(from: currentTier, to: previous)
            currentTier = previous
            inTierProgress = 1
        } else {
            inTierProgress = newProgress.clamped(to: 0...1)
        }
    }

    /// Scene calls this after consuming the transition (LOD swap done).
    public mutating func consumeTransition() {
        pendingTransition = nil
    }

    /// Direct-tier snap (e.g. tapping a tier badge). Sets a transition so the
    /// scene can still play the LOD swap animation.
    public mutating func snap(to tier: ZoomTier) {
        guard tier != currentTier else { return }
        pendingTransition = tier.rawValue > currentTier.rawValue
            ? .zoomingIn(from: currentTier, to: tier)
            : .zoomingOut(from: currentTier, to: tier)
        currentTier = tier
        inTierProgress = 0
    }
}

private extension Double {
    nonisolated func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
