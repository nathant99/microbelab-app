import Foundation
import Models

/// Deterministic per-tick simulator for the gut microbiome.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § New Engines: feeding mode + antibiotic
/// shock + recovery state drive the per-tick population delta. Pure value
/// type, seedable RNG — same input sequence always produces same output
/// per `.claude/rules/state-machines.md` § Testing State Machines.
public nonisolated struct MicrobiomeSimulator: Sendable {
    public let microbes: [MicrobeCharacter]
    /// Hard floor + ceiling per microbe — keeps populations bounded so the
    /// simulator doesn't drift into integer overflow over long sessions.
    public let populationFloor: Int
    public let populationCeiling: Int

    public init(
        microbes: [MicrobeCharacter],
        populationFloor: Int = 0,
        populationCeiling: Int = 10_000
    ) {
        self.microbes = microbes
        self.populationFloor = populationFloor
        self.populationCeiling = populationCeiling
    }

    /// Advance one tick. Antibiotic shock collapses populations across the
    /// board; recovery applies a slow restoration curve. Outside those states,
    /// per-microbe growth follows the feeding-mode modifier.
    public func tick(_ state: MicrobiomeState) -> MicrobiomeState {
        var populations = state.populations

        for microbe in microbes {
            let current = populations[microbe.id] ?? populationFloor
            let next: Int

            switch state.antibioticState {
            case .none:
                let modifier = microbe.growthRate.modifier(for: state.feedingMode)
                let delta = Int((Double(current) * modifier).rounded())
                // Seed-from-zero: a microbe that's never been spotted enters
                // at a small base count when its feeding mode is favorable.
                if current == 0, modifier > 0.2 {
                    next = 8
                } else {
                    next = current + delta
                }
            case .active:
                next = Int(Double(current) * 0.4)
            case .recovering:
                next = current + max(1, Int(Double(current) * 0.1))
            }
            populations[microbe.id] = next.clamped(to: populationFloor...populationCeiling)
        }

        let nextAntibiotic = advance(antibioticState: state.antibioticState)

        return MicrobiomeState(
            populations: populations,
            feedingMode: state.feedingMode,
            antibioticState: nextAntibiotic,
            tickCount: state.tickCount + 1,
            activeSlot: state.activeSlot
        )
    }

    private func advance(antibioticState: AntibioticState) -> AntibioticState {
        switch antibioticState {
        case .none:
            return .none
        case .active(let daysLeft) where daysLeft > 1:
            return .active(daysLeft: daysLeft - 1)
        case .active:
            // Last active tick — transition into recovery.
            return .recovering(ticksLeft: 12)
        case .recovering(let ticksLeft) where ticksLeft > 1:
            return .recovering(ticksLeft: ticksLeft - 1)
        case .recovering:
            return .none
        }
    }
}

private extension Int {
    nonisolated func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
