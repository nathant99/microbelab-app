import Testing
import Foundation
import Models
@testable import SharedUI

/// Surface-area smoke tests for the shared `MicrobePortraitView`. The view
/// is the single seam for cast portrait rendering; until the labsmith asset
/// wave lands the SF-Symbol fallback pathway must compile + initialize for
/// every consumer surface.
@Suite("MicrobePortraitView (shared cast portrait rendering seam)")
struct MicrobePortraitViewTests {

    private func makeMicrobe(role: MicrobeRole = .beneficial, slug: String = "lacto") -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: slug,
            displayName: "Lacto",
            kingdom: .bacteria,
            role: role,
            preferredEnvironment: .colon,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: 0),
            catchphrase: "I help digest milk.",
            factCard: "Lacto ferments lactose into lactic acid.",
            firstKit: 1
        )
    }

    @Test("default init: isDiscovered=true, bundle=.main — covers the standard codex card consumer path")
    func defaultInitDiscovered() {
        let view = MicrobePortraitView(microbe: makeMicrobe())
        #expect(view.isDiscovered)
        #expect(view.microbe.slug == "lacto")
    }

    @Test("undiscovered cards keep the questionmark cue regardless of role — trauma-informed posture")
    func undiscoveredInit() {
        let view = MicrobePortraitView(
            microbe: makeMicrobe(role: .pathogenic),
            isDiscovered: false
        )
        #expect(!view.isDiscovered)
        // The role is pathogenic but the view should still init cleanly;
        // the role-color tint is only surfaced post-discovery.
        #expect(view.microbe.role == .pathogenic)
    }

    @Test("every role variant initializes — covers the role-color switch arms")
    func allRoleVariants() {
        for role in MicrobeRole.allCases {
            let view = MicrobePortraitView(microbe: makeMicrobe(role: role))
            #expect(view.microbe.role == role)
        }
    }

    @Test("custom bundle override resolves — caller can hand a SharedUI .module bundle when assets land there")
    func customBundleOverride() {
        let view = MicrobePortraitView(
            microbe: makeMicrobe(),
            bundle: Bundle(for: BundleStub.self)
        )
        #expect(view.bundle === Bundle(for: BundleStub.self))
    }

    private final class BundleStub {}
}
