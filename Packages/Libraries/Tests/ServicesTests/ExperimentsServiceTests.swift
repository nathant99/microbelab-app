import Foundation
import Testing
import ForgeExperiments
@testable import Services

@Suite("ExperimentsService")
@MainActor
struct ExperimentsServiceTests {

    @Test func defaultExperimentsRegistered() {
        let service = ExperimentsService(seed: "test-seed-1")
        // Both pilot experiments are registered at construction time.
        #expect(service.assignedVariant(for: ExperimentsService.progressiveDisclosureV2ID) != nil)
        #expect(service.assignedVariant(for: ExperimentsService.seasonalContentGateID) != nil)
    }

    @Test func unregisteredExperimentReturnsNil() {
        let service = ExperimentsService(seed: "test-seed-2")
        #expect(service.assignedVariant(for: "does-not-exist") == nil)
    }

    @Test func defaultAssignmentsAreControl() {
        // Both pilots default to 100% control / 0% treatment until a focused
        // Phase 2 / Phase 4 round flips the weights. Verify the default
        // catalog ships in that posture so no kid sees a Phase 4 surface
        // before the round lands.
        let service = ExperimentsService(seed: "test-seed-3")
        #expect(service.assignedVariant(for: ExperimentsService.progressiveDisclosureV2ID)?.id == "control")
        #expect(service.assignedVariant(for: ExperimentsService.seasonalContentGateID)?.id == "control")
    }

    @Test func sameSeedSameAssignment() {
        // Deterministic SHA256 bucketing means same seed + same experimentID =
        // same variant across multiple service instances. This is what makes
        // the assignment stable across launches without persisting it.
        let serviceA = ExperimentsService(seed: "stable-seed")
        let serviceB = ExperimentsService(seed: "stable-seed")
        #expect(serviceA.assignedVariant(for: ExperimentsService.progressiveDisclosureV2ID)?.id ==
                serviceB.assignedVariant(for: ExperimentsService.progressiveDisclosureV2ID)?.id)
    }

    @Test func differentSeedsCanProduceDifferentAssignments() {
        // Confirms the bucketing function does take the seed into account.
        // With a 50/50 split, different seeds eventually produce different
        // variants. We use a custom 50/50 experiment to verify this without
        // depending on the default (100% control) catalogue.
        let experiment = ExperimentDefinition(
            id: "fifty-fifty",
            name: "Even Split",
            description: "50/50 split for assignment determinism testing.",
            variants: [
                Variant(id: "a", name: "Variant A", weight: 50),
                Variant(id: "b", name: "Variant B", weight: 50),
            ],
            startDate: Date(),
            endDate: Date().addingTimeInterval(60 * 60)
        )

        // Find two seeds that bucket to different variants. Try a small
        // search space; SHA256 spreads buckets uniformly so this terminates
        // quickly.
        var sawA = false
        var sawB = false
        for index in 0..<32 {
            let service = ExperimentsService(seed: "split-\(index)", experiments: [experiment])
            let variant = service.assignedVariant(for: "fifty-fifty")
            if variant?.id == "a" { sawA = true }
            if variant?.id == "b" { sawB = true }
            if sawA && sawB { break }
        }
        #expect(sawA && sawB, "32 uniformly-bucketed seeds must produce both variants in a 50/50 split")
    }

    @Test func isEnabledMatchesEnabledVariantID() {
        // Custom experiment that forces 100% to the 'enabled' variant — the
        // boolean shortcut should return true.
        let experiment = ExperimentDefinition(
            id: "force-enabled",
            name: "Force Enabled",
            description: "Single-variant experiment forcing enabled state for shortcut testing.",
            variants: [
                Variant(id: "enabled", name: "Enabled", weight: 100),
            ],
            startDate: Date(),
            endDate: Date().addingTimeInterval(60 * 60)
        )
        let service = ExperimentsService(seed: "enabled-seed", experiments: [experiment])
        #expect(service.isEnabled("force-enabled"))
        #expect(!service.isEnabled("does-not-exist"))
    }

    @Test func intParameterReadsFromAssignedVariant() {
        // The 'staged' variant of the default progressive-disclosure
        // experiment carries an earlyUnlockTicks Int parameter. Pin a custom
        // experiment forcing 100% staged so we can read the parameter
        // deterministically.
        let staged = Variant(id: "staged", name: "Staged", weight: 100, parameters: [
            "earlyUnlockTicks": .int(2),
        ])
        let experiment = ExperimentDefinition(
            id: "force-staged",
            name: "Force Staged",
            description: "Single-variant experiment forcing staged state for parameter testing.",
            variants: [staged],
            startDate: Date(),
            endDate: Date().addingTimeInterval(60 * 60)
        )
        let service = ExperimentsService(seed: "staged-seed", experiments: [experiment])
        #expect(service.intParameter("earlyUnlockTicks", in: "force-staged", default: 0) == 2)
        // Missing key falls back to the default.
        #expect(service.intParameter("missing-key", in: "force-staged", default: 99) == 99)
        // Wrong type falls back to the default.
        #expect(service.doubleParameter("earlyUnlockTicks", in: "force-staged", default: 99.5) == 99.5)
    }

    @Test func defaultsHaveSensibleMetadata() {
        let defaults = ExperimentsService.defaultExperiments()
        #expect(defaults.count == 2)
        for definition in defaults {
            // Each definition must have at least one variant with non-zero weight
            // (otherwise ForgeExperiments.ExperimentAssigner traps on
            // precondition).
            let totalWeight = definition.variants.reduce(0) { $0 + $1.weight }
            #expect(totalWeight > 0, "experiment \(definition.id) must have total variant weight > 0")
            // Minimum sessions must be > 0 to be a real experiment.
            #expect(definition.minimumSessions > 0)
            // End date must be after start.
            #expect(definition.endDate > definition.startDate)
        }
    }
}
