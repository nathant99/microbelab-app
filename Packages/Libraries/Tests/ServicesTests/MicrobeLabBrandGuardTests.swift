import Testing
import Foundation
@testable import Services

@Suite("MicrobeLabBrandGuard (ForgeLocalization brand-protection wrapper)")
struct MicrobeLabBrandGuardTests {

    @Test("app name is protected")
    func appNameProtected() {
        #expect(MicrobeLabBrandGuard.shared.isProtected("MicrobeLab"))
    }

    @Test("Phase 1 cast names are protected")
    func phase1CastProtected() {
        let phase1 = ["Lacto", "Yeast", "Photo", "Net", "Spore", "Guard",
                      "Bifido", "Akker", "Strep", "Coli", "Rhino", "Deino"]
        for name in phase1 {
            #expect(MicrobeLabBrandGuard.shared.isProtected(name),
                    "Phase 1 cast member \(name) should be brand-protected")
        }
    }

    @Test("Phase 2 cast names are protected")
    func phase2CastProtected() {
        let phase2 = ["Sebu", "Demi", "Halo", "Pylo", "Sweet", "Nodu", "Therm", "Loam"]
        for name in phase2 {
            #expect(MicrobeLabBrandGuard.shared.isProtected(name),
                    "Phase 2 cast member \(name) should be brand-protected")
        }
    }

    @Test("mentor names are protected")
    func mentorNamesProtected() {
        #expect(MicrobeLabBrandGuard.shared.isProtected("Vee"))
        #expect(MicrobeLabBrandGuard.shared.isProtected("Cilia"))
    }

    @Test("ForgeKit baseline terms are also protected (inherited from ForgeBrandGuard)")
    func forgeKitBaselineProtected() {
        #expect(MicrobeLabBrandGuard.shared.isProtected("ForgeKit"))
        #expect(MicrobeLabBrandGuard.shared.isProtected("Forge"))
    }

    @Test("NGSS standards are protected")
    func ngssProtected() {
        #expect(MicrobeLabBrandGuard.shared.isProtected("NGSS"))
        #expect(MicrobeLabBrandGuard.shared.isProtected("MS-LS1-1"))
        #expect(MicrobeLabBrandGuard.shared.isProtected("MS-LS1-3"))
    }

    @Test("non-brand strings are NOT protected (defaults to translation)")
    func nonBrandStringsNotProtected() {
        #expect(!MicrobeLabBrandGuard.shared.isProtected("microbiome"))
        #expect(!MicrobeLabBrandGuard.shared.isProtected("immune system"))
        #expect(!MicrobeLabBrandGuard.shared.isProtected("zoom in"))
    }

    @Test("verbatim(_:) returns the string unchanged (semantic marker)")
    func verbatimReturnsUnchanged() {
        let guarded = MicrobeLabBrandGuard.shared.verbatim("MicrobeLab")
        #expect(guarded == "MicrobeLab")
    }

    @Test("canonical protected terms list contains 20 cast members + app + 2 mentors + 3 methodology + 5 NGSS = 31 minimum")
    func canonicalTermsList() {
        let canonical = MicrobeLabBrandGuard.canonicalProtectedTerms
        // 20 cast + 1 app + 2 mentor + 3 methodology + 5 NGSS = 31
        #expect(canonical.count == 31)
    }

    @Test("canonical protected terms list has no duplicates")
    func canonicalTermsListHasNoDuplicates() {
        let canonical = MicrobeLabBrandGuard.canonicalProtectedTerms
        let uniqued = Set(canonical)
        #expect(canonical.count == uniqued.count,
                "Duplicate protected term in canonical list: \(canonical)")
    }
}
