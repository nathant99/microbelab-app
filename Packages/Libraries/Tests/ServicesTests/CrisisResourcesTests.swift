import Foundation
import Testing
@testable import Services

@Suite("CrisisResources")
struct CrisisResourcesTests {
    @Test func allListContainsCanonicalResources() {
        let ids = CrisisResources.all.map(\.id)
        #expect(ids == ["988", "childhelp", "crisis-text-line"])
    }

    @Test func resourceURLsUseOnlySafeSchemes() {
        // Pin the trauma-safe set: tel: / sms: / https: only. https isn't
        // currently in use but the test catches future additions that
        // might accidentally include a non-deep-link.
        for resource in CrisisResources.all {
            let scheme = resource.actionURL.scheme ?? ""
            #expect(["tel", "sms", "https"].contains(scheme),
                    "resource \(resource.id) has unsafe scheme \(scheme)")
        }
    }

    @Test func lifeline988URLPointsAt988() {
        #expect(CrisisResources.lifeline988.actionURL.absoluteString == "tel:988")
    }

    @Test func childhelpURLPointsAtCanonicalNumber() {
        #expect(CrisisResources.childhelp.actionURL.absoluteString == "tel:18004224453")
    }

    @Test func crisisTextLineURLPrefillsHomeBody() {
        // The sms: scheme accepts an optional body parameter; pre-filling
        // "HOME" so the kid only has to tap Send is canonical Crisis Text
        // Line guidance.
        #expect(CrisisResources.crisisTextLine.actionURL.absoluteString.contains("741741"))
        #expect(CrisisResources.crisisTextLine.actionURL.absoluteString.contains("HOME"))
    }

    @Test func allResourcesHaveNonEmptyDisplayCopy() {
        // Trauma-informed framing requires every row to have a title,
        // subtitle, and actionLabel — empty strings would surface as a
        // blank tap-target.
        for resource in CrisisResources.all {
            #expect(!resource.title.isEmpty)
            #expect(!resource.subtitle.isEmpty)
            #expect(!resource.actionLabel.isEmpty)
        }
    }
}
