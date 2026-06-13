import Testing
import Foundation
@testable import Services

@Suite("ImmuneDefenseTrophy")
struct ImmuneDefenseTrophyTests {

    private func fixture(
        wavesCleared: Int,
        totalWaves: Int = 5,
        finalScore: Int = 0,
        perfectRun: Bool = false,
        displayName: String = "Explorer"
    ) -> ImmuneDefenseTrophy {
        ImmuneDefenseTrophy(
            displayName: displayName,
            wavesCleared: wavesCleared,
            totalWaves: totalWaves,
            finalScore: finalScore,
            perfectRun: perfectRun,
            issuedAt: Date(timeIntervalSince1970: 1_780_000_000)
        )
    }

    @Test("Zero-wave headline frames the start as agency, not absence")
    func zeroWaveHeadlineIsAgentic() {
        let trophy = fixture(wavesCleared: 0)
        #expect(trophy.headline == "Defense Cadet")
        #expect(trophy.subline == "Your macrophages are warmed up and waiting.")
    }

    @Test("Low-wave headline scales warmly without comparison framing")
    func lowWaveHeadlineWarmsUp() {
        let trophy = fixture(wavesCleared: 1, finalScore: 40)
        #expect(trophy.headline == "Defense Apprentice")
        // Subline never benchmarks the kid against anyone else.
        #expect(trophy.subline.contains("held the line"))
        #expect(!trophy.subline.contains("only"))
        #expect(!trophy.subline.contains("just"))
    }

    @Test("Mid-wave headline upgrades to Specialist")
    func midWaveHeadline() {
        let trophy = fixture(wavesCleared: 3, finalScore: 120)
        #expect(trophy.headline == "Defense Specialist")
    }

    @Test("Full-clear non-perfect run earns Champion (not Master)")
    func fullClearHeadlineIsChampion() {
        let trophy = fixture(wavesCleared: 5, finalScore: 220, perfectRun: false)
        #expect(trophy.headline == "Defense Champion")
        #expect(trophy.subline == "You held the line through every wave.")
    }

    @Test("Perfect full-clear earns Master with distinct subline")
    func perfectFullClearHeadlineIsMaster() {
        let trophy = fixture(wavesCleared: 5, finalScore: 300, perfectRun: true)
        #expect(trophy.headline == "Defense Master")
        #expect(trophy.subline == "Every wave clear, zero pathogens missed.")
    }

    @Test("Perfect-run flag without full clear does NOT crown Master")
    func perfectRunWithoutFullClearStillSpecialist() {
        // Defensive: perfectRun is only meaningful when paired with all
        // waves cleared. The headline picker requires BOTH conditions for
        // the top tier — perfectRun alone shouldn't crown the kid Master.
        let trophy = fixture(wavesCleared: 3, finalScore: 150, perfectRun: true)
        #expect(trophy.headline == "Defense Specialist")
    }

    @Test("Singular vs plural copy matches wave count")
    func singularVsPluralCopy() {
        let one = fixture(wavesCleared: 1)
        let two = fixture(wavesCleared: 2)
        #expect(one.subline.contains("1 wave"))
        #expect(!one.subline.contains("waves"))
        #expect(two.subline.contains("2 waves"))
    }

    @Test("Score and wave labels surface monospaced-digit-friendly strings")
    func chipLabels() {
        let trophy = fixture(wavesCleared: 4, totalWaves: 5, finalScore: 175)
        #expect(trophy.waveLabel == "4 / 5 waves")
        #expect(trophy.scoreLabel == "175 pts")
    }

    @Test("Issued-on label uses the long date style")
    func issuedOnLabel() {
        let trophy = fixture(wavesCleared: 3)
        let label = trophy.issuedOnLabel(calendar: Calendar(identifier: .gregorian))
        #expect(label.hasPrefix("Issued "))
        // The fixture date is January 2026; assert the year surfaces so the
        // formatter path is exercised. Don't pin the exact string because
        // locale formatting can legitimately differ.
        #expect(label.contains("2026"))
    }

    @Test("Trauma-informed copy invariants: no shame / loss / comparison language at any count")
    func traumaInformedCopyInvariants() {
        let stoplist = [
            "missed", "failure", "behind", "should", "must",
            "almost", "fell short", "compared", "better than", "lost"
        ]
        for waves in 0...5 {
            for perfect in [false, true] {
                let trophy = fixture(wavesCleared: waves, perfectRun: perfect)
                let combined = "\(trophy.headline) \(trophy.subline)".lowercased()
                for forbidden in stoplist {
                    // Allow "missed" only in the perfect-master subline where
                    // it's literally "zero pathogens missed" (positive framing).
                    if forbidden == "missed", trophy.subline.contains("zero pathogens missed") {
                        continue
                    }
                    #expect(
                        !combined.contains(forbidden),
                        "Forbidden register token '\(forbidden)' in waves=\(waves) perfect=\(perfect) trophy"
                    )
                }
            }
        }
    }

    @Test("Codable roundtrip preserves all fields")
    func codableRoundtrip() throws {
        let original = fixture(wavesCleared: 4, finalScore: 200, perfectRun: false, displayName: "Sam")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ImmuneDefenseTrophy.self, from: data)
        #expect(decoded == original)
    }
}
