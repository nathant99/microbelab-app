import Foundation

/// Codex completion certificate — pure value-type snapshot of the kid's discovery progress
/// captured at the moment the kid taps "Share my codex" in the Progress tab. Future-session
/// activity doesn't retroactively change a certificate the kid has shared.
///
/// Trauma-informed posture: the certificate frames the kid's progress as recognition, never
/// as comparison ("X / Y discovered" + a warm headline that scales with the count). Counts
/// stay on-device; the certificate's `transferable` form ships only the rendered image
/// representation (no underlying data leaves the device until the kid explicitly shares it).
///
/// Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Share-worthy moments": codex completion
/// certificates + immune-game high-score trophies are the canonical share-worthy surfaces;
/// this value type closes the codex-completion axis.
public nonisolated struct CodexCertificate: Sendable, Equatable, Codable {
    /// The kid's display name (defaults to "Explorer" when not set per
    /// `PlayerProgressData.displayName`).
    public let displayName: String
    /// Number of microbes the kid has discovered in the codex.
    public let microbesDiscovered: Int
    /// Total microbes available in the catalog at the moment the certificate is captured.
    public let microbesTotal: Int
    /// Issue date — captured at the moment the certificate is shared.
    public let issuedAt: Date

    public init(
        displayName: String,
        microbesDiscovered: Int,
        microbesTotal: Int,
        issuedAt: Date
    ) {
        self.displayName = displayName
        self.microbesDiscovered = microbesDiscovered
        self.microbesTotal = microbesTotal
        self.issuedAt = issuedAt
    }

    /// Headline shown at the top of the certificate. Scales the warmth of the framing to the
    /// kid's progress without ever framing low discovery counts as failure.
    public var headline: String {
        switch microbesDiscovered {
        case 0:
            // No discoveries yet — the certificate frames the start as agency, not absence.
            return "Microbe Explorer Pass"
        case 1...3:
            return "Microbe Field Notebook"
        case 4...8:
            return "Microbe Naturalist"
        case 9..<microbesTotal:
            return "Microbe Scientist"
        default:
            return "Codex Complete!"
        }
    }

    /// Subline shown beneath the headline. Trauma-informed: never frames discovery count
    /// as a benchmark to beat; always frames it as a record of "you've met N microbes".
    public var subline: String {
        if microbesDiscovered == 0 {
            return "Your codex is open and waiting."
        }
        if microbesDiscovered >= microbesTotal && microbesTotal > 0 {
            return "You met every microbe in the catalog."
        }
        let plural = microbesDiscovered == 1 ? "microbe" : "microbes"
        return "You've met \(microbesDiscovered) \(plural) so far."
    }

    /// Issued-on string surfaced in the certificate footer.
    public func issuedOnLabel(calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.calendar = calendar
        return "Issued \(formatter.string(from: issuedAt))"
    }
}
