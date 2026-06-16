import Foundation

/// One safety hotline / crisis-text-line surfaced in the app's
/// crisis-resource card. Pure value type — display copy + tap-action URL
/// live together so the UI doesn't need to hand-author either side.
public nonisolated struct CrisisResource: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let actionLabel: String
    /// The deep-link the row taps into. `tel:` / `sms:` / `https:` only.
    public let actionURL: URL

    public init(
        id: String,
        title: String,
        subtitle: String,
        actionLabel: String,
        actionURL: URL
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.actionURL = actionURL
    }
}

/// Portfolio-canonical safety surface per the trauma-informed-content rule
/// (988 + Childhelp + Crisis Text Line). Surfaced from `SettingsView` so
/// a kid OR a parent can reach it without leaving the app. Future surfaces
/// (Phase 3 disease-story arcs, despair-signal detection) will reach into
/// the same list so the resource set stays one definition wide.
///
/// **Trauma-informed framing** (per `.claude/rules/trauma-informed-content.md`):
/// the card uses validate-then-inform / hold-space copy. Resources are
/// presented as gentle options, not as alarms. Each row's `subtitle` names
/// the audience without pathologizing them.
public nonisolated enum CrisisResources {
    /// Force-unwrap is safe here — the URLs are hard-coded ASCII literals
    /// known to be valid at compile time. (`init?(string:)` only fails on
    /// malformed input, which these never are.) Per the `.claude/rules/swiftlint.md`
    /// guidance on suppressing force_unwrapping: documented safety proof
    /// inline so future edits can verify the invariant.
    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Hard-coded crisis-resource URL is malformed: \(string)")
        }
        return url
    }

    public static let lifeline988 = CrisisResource(
        id: "988",
        title: "988 Suicide & Crisis Lifeline",
        subtitle: "Call or text 988 — free, confidential, 24/7. For you or someone you care about.",
        actionLabel: "Call 988",
        actionURL: url("tel:988")
    )

    public static let childhelp = CrisisResource(
        id: "childhelp",
        title: "Childhelp",
        subtitle: "1-800-4-A-CHILD (1-800-422-4453). For kids + grown-ups — safe to call any time.",
        actionLabel: "Call 1-800-422-4453",
        actionURL: url("tel:18004224453")
    )

    public static let crisisTextLine = CrisisResource(
        id: "crisis-text-line",
        title: "Crisis Text Line",
        subtitle: "Text HOME to 741741. Type instead of talk — a real person answers.",
        actionLabel: "Text HOME to 741741",
        actionURL: url("sms:741741&body=HOME")
    )

    /// Canonical ordered list. Order matters: 988 first because it's the
    /// most-recognized + broadest-applicable number; Childhelp second
    /// (kid-specific); Crisis Text Line third (alternate modality).
    public static let all: [CrisisResource] = [
        lifeline988,
        childhelp,
        crisisTextLine,
    ]
}
