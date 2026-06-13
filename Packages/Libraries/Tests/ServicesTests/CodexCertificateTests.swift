import Testing
import Foundation
@testable import Services

@Suite("CodexCertificate")
struct CodexCertificateTests {

    private func fixture(
        discovered: Int,
        total: Int = 12,
        displayName: String = "Explorer"
    ) -> CodexCertificate {
        CodexCertificate(
            displayName: displayName,
            microbesDiscovered: discovered,
            microbesTotal: total,
            issuedAt: Date(timeIntervalSince1970: 1_780_000_000)
        )
    }

    @Test("Zero-discovery headline frames the start as agency, not absence")
    func zeroDiscoveryHeadlineIsAgentic() {
        let certificate = fixture(discovered: 0)
        #expect(certificate.headline == "Microbe Explorer Pass")
        #expect(certificate.subline == "Your codex is open and waiting.")
    }

    @Test("Low-discovery headline scales warmly without comparison framing")
    func lowDiscoveryHeadlineWarmsUp() {
        let certificate = fixture(discovered: 2)
        #expect(certificate.headline == "Microbe Field Notebook")
        // Subline never benchmarks the kid against anyone else.
        #expect(certificate.subline.contains("met"))
        #expect(!certificate.subline.contains("only"))
        #expect(!certificate.subline.contains("just"))
    }

    @Test("Mid-discovery headline upgrades to Naturalist")
    func midDiscoveryHeadline() {
        let certificate = fixture(discovered: 5)
        #expect(certificate.headline == "Microbe Naturalist")
    }

    @Test("Near-complete headline upgrades to Scientist (but not Complete yet)")
    func nearCompleteHeadline() {
        let certificate = fixture(discovered: 11, total: 12)
        #expect(certificate.headline == "Microbe Scientist")
        #expect(certificate.subline.contains("11"))
    }

    @Test("Complete headline celebrates the full codex")
    func completeHeadline() {
        let certificate = fixture(discovered: 12, total: 12)
        #expect(certificate.headline == "Codex Complete!")
        #expect(certificate.subline == "You met every microbe in the catalog.")
    }

    @Test("Singular vs plural copy matches discovery count")
    func singularVsPluralCopy() {
        let one = fixture(discovered: 1)
        let two = fixture(discovered: 2)
        #expect(one.subline.contains("1 microbe"))
        #expect(!one.subline.contains("microbes"))
        #expect(two.subline.contains("2 microbes"))
    }

    @Test("Issued-on label uses the long date style")
    func issuedOnLabel() {
        let certificate = fixture(discovered: 5)
        let label = certificate.issuedOnLabel(calendar: Calendar(identifier: .gregorian))
        #expect(label.hasPrefix("Issued "))
        // The fixture date is January 2026; assert the year surfaces so the formatter
        // path is exercised. Don't pin the exact string because locale formatting can
        // legitimately differ.
        #expect(label.contains("2026"))
    }

    @Test("Trauma-informed copy invariants: no shame / loss / failure language at any count")
    func traumaInformedCopyInvariants() {
        let stoplist = ["missed", "failure", "behind", "should", "must", "haven't yet", "fell short"]
        for n in 0...12 {
            let certificate = fixture(discovered: n)
            let combined = "\(certificate.headline) \(certificate.subline)".lowercased()
            for forbidden in stoplist {
                #expect(!combined.contains(forbidden), "Forbidden register token '\(forbidden)' in count=\(n) certificate")
            }
        }
    }

    @Test("Codable roundtrip preserves all fields")
    func codableRoundtrip() throws {
        let original = fixture(discovered: 7, displayName: "Sam")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CodexCertificate.self, from: data)
        #expect(decoded == original)
    }
}
