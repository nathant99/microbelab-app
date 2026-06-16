import Testing
import Foundation
import Models
@testable import SharedUI

@Suite("MicrobeCodexCard (cross-microbe ecology edge surfacing)")
struct MicrobeCodexCardTests {

    private func makeMicrobe() -> MicrobeCharacter {
        MicrobeCharacter(
            id: UUID(),
            slug: "lacto",
            displayName: "Lacto",
            kingdom: .bacteria,
            role: .beneficial,
            preferredEnvironment: .colon,
            growthRate: GrowthRate(onFiber: 0.5, onSugar: -0.2, onBalanced: 0.2, onNone: 0),
            catchphrase: "I help digest milk.",
            factCard: "Lacto ferments lactose into lactic acid.",
            firstKit: 1
        )
    }

    @Test("default init: same-kind cohort defaults to empty so existing callers don't need to thread the new accessor")
    func defaultInit() {
        let card = MicrobeCodexCard(microbe: makeMicrobe(), isDiscovered: true)
        #expect(card.livesNearDisplayNames.isEmpty)
        #expect(card.sameKindDisplayNames.isEmpty)
    }

    @Test("explicit same-kind cohort is preserved on the card")
    func sameKindCohortStored() {
        let card = MicrobeCodexCard(
            microbe: makeMicrobe(),
            isDiscovered: true,
            sameKindDisplayNames: ["Bifido", "Akker"]
        )
        #expect(card.sameKindDisplayNames == ["Bifido", "Akker"])
    }

    @Test("both cohorts can coexist — habitat + kingdom edge classes surface independently")
    func bothCohortsCoexist() {
        let card = MicrobeCodexCard(
            microbe: makeMicrobe(),
            isDiscovered: true,
            livesNearDisplayNames: ["Bifido"],
            sameKindDisplayNames: ["Akker", "Strep"]
        )
        #expect(card.livesNearDisplayNames == ["Bifido"])
        #expect(card.sameKindDisplayNames == ["Akker", "Strep"])
    }
}
