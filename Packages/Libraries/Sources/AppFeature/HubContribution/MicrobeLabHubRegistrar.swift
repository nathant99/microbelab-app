import Foundation
import ForgeAdventure

/// Lightweight registrar that registers MicrobeLab's `HubContribution` against a passed-in
/// `HubContributionRegistry` actor. AdventureHub owns the canonical registry instance — source
/// apps don't share one directly. When AdventureHub-side integration lands (FEATURE_PLAN.md
/// § Phase 4 Microbiome Worlds + Classroom), the hub will call `MicrobeLabHubRegistrar.register`
/// with its own registry; until then this registrar is exercised only by unit tests that pin
/// the contribution shape.
public enum MicrobeLabHubRegistrar {
    /// Registers MicrobeLab's canonical Level 2 contribution into the supplied registry.
    /// Idempotent: re-registering the same contribution overwrites the slot per
    /// `HubContributionRegistry.register(_:)` semantics. The default contribution targets
    /// `.scienceLabs` (closest available match) until labsmith adds a canonical `lifeZone`
    /// case to `ZoneID` — see `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md`.
    public static func register(
        into registry: HubContributionRegistry,
        contribution: MicrobeLabHubContribution = MicrobeLabHubContribution()
    ) async {
        await registry.register(contribution)
    }
}
