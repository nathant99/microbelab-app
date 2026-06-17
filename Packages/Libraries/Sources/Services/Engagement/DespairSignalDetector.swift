import Foundation

/// Pure-value despair-signal screen for kid-authored free text (reflection
/// entries, mentor prompts). Pairs with `CrisisResources` so the existing
/// 988 / Childhelp / Crisis Text Line surface auto-reaches the kid the moment
/// a despair phrase is detected — never an extra hop through Settings.
///
/// Closes FEATURE_PLAN line 161 (Phase 3 "Implement crisis-resource surfacing
/// if despair signals detected"). Defense-in-depth alongside the existing
/// always-on Settings surface (`SettingsView` → "If you need to talk to
/// someone" section); the detector adds an additional reactive layer so the
/// kid doesn't need to navigate to find support.
///
/// **Trauma-informed posture** (per `.claude/rules/trauma-informed-content.md`
/// + SAMHSA TIP 57 register):
///
/// - The stoplist matches **explicit despair / crisis tokens** authored by
///   the National Suicide Prevention Hotline guidance + Crisis Text Line
///   training material — NOT a broad "sad word" list (low false-positive
///   tolerance for kids who say "this is hard" — those land at `.calm`).
/// - Match semantics are PHRASE-level (multi-word), not token-level, so
///   ordinary words ("I want to go to the moon" doesn't match "want to die").
/// - All matches are case-insensitive + diacritic-folded so "I can't go on"
///   matches both "i cant go on" and "I can´t go on".
/// - The detector is intentionally CONSERVATIVE — it's not a substitute for
///   clinical screening; false-negative cost is non-zero. The hedge is
///   surfaced verbatim in the displayed copy ("If something hurts more than
///   this app can hold, here are people trained to help"). Per
///   `.claude/rules/ai-content.md` § Hedging language.
/// - False-positive cost is structurally low because the surface presented
///   is the existing portfolio-canonical resource list — never a forced
///   call, never a dialog the kid can't dismiss; the trauma-informed
///   posture per `.claude/rules/forgekit.md` says "never harmful to surface
///   support resources".
///
/// **Privacy** (per `.claude/rules/age-assurance.md` § Portfolio Status):
/// detection is fully on-device. The text passes through the detector + is
/// discarded; only a categorical `.calm` / `.elevated(...)` result reaches
/// the consumer surface. Never logs free-text per `.claude/rules/debug-logging.md`
/// § Privacy by default — never log raw user data.
public nonisolated struct DespairSignalDetector: Sendable {

    public nonisolated enum Severity: Sendable, Equatable {
        /// No despair signal detected. Default; the reflection entry flows
        /// through the standard journal pipeline.
        case calm

        /// Distress-tier signal (e.g., "i'm scared", "i feel alone") — not
        /// a crisis-tier match but worth surfacing the support card calmly.
        case elevatedDistress

        /// Crisis-tier signal (e.g., explicit suicidal ideation, hopelessness
        /// framing). Crisis-resource card surfaces above the standard
        /// summary acknowledgement; the kid + parent both see it.
        case elevatedCrisis
    }

    /// Crisis-tier phrases — explicit despair / suicidal-ideation language.
    /// Conservative selection: each entry is a literal phrase the kid would
    /// have to author. Single tokens like "die" or "kill" are NOT included
    /// (false-positive rate against game language too high — "die" appears
    /// in immune-game pathogen vocabulary stoplist tests).
    ///
    /// The list is the canonical SAMHSA TIP 57 + Crisis Text Line training
    /// markers, lowercased + diacritic-folded so the matcher only does
    /// substring comparison after normalization.
    nonisolated static let crisisPhrases: [String] = [
        "want to die",
        "wish i was dead",
        "wish i were dead",
        "kill myself",
        "end my life",
        "end it all",
        "no reason to live",
        "i can't go on",
        "i cant go on",
        "give up on life",
        "better off dead",
        "everyone better without me",
        "don't want to be here anymore",
        "dont want to be here anymore",
        "nothing matters anymore",
        "hurt myself",
        "want to hurt myself",
    ]

    /// Distress-tier phrases — markers of overwhelm / isolation / hopelessness
    /// that don't rise to crisis but warrant the support-card surface.
    nonisolated static let distressPhrases: [String] = [
        "no one cares",
        "nobody cares",
        "no one loves me",
        "nobody loves me",
        "i'm alone",
        "im alone",
        "i feel alone",
        "i'm scared",
        "im scared",
        "i feel scared",
        "i hate myself",
        "i can't do this",
        "i cant do this",
        "everything is wrong",
        "i feel hopeless",
    ]

    public nonisolated init() {}

    /// Detect despair signals in `text`. Returns the highest-severity match;
    /// crisis-tier wins over distress-tier (a paragraph that includes both
    /// surfaces the crisis card).
    ///
    /// Empty / nil-like text always returns `.calm`.
    public nonisolated func detect(in text: String) -> Severity {
        let normalized = Self.normalize(text)
        guard !normalized.isEmpty else { return .calm }

        for phrase in Self.crisisPhrases where normalized.contains(phrase) {
            return .elevatedCrisis
        }
        for phrase in Self.distressPhrases where normalized.contains(phrase) {
            return .elevatedDistress
        }
        return .calm
    }

    /// Lowercase + diacritic-fold + collapse multiple spaces. Pure-value;
    /// the result is discarded immediately so no PII / free-text persists
    /// past this call.
    nonisolated static func normalize(_ text: String) -> String {
        // Lowercase + ASCII-fold so "I CAN´T GO ON" and "i can't go on" both
        // match the same crisis phrase.
        let folded = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil)
            .lowercased()
        // Collapse all whitespace runs to a single space so accidental
        // double-spaces don't break a phrase match.
        let collapsed = folded
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return collapsed
    }
}

/// Trauma-informed reactive surface for a despair signal. View consumers
/// read `presentation(for:)` and surface the support card when non-nil.
///
/// Mirrors the static `CrisisResources.all` list — the card surface IS
/// the same one Settings already exposes. Trauma-informed posture: the
/// kid can always dismiss; no modal trap; no forced call.
public nonisolated enum DespairSignalSurface: Sendable {

    public nonisolated struct Presentation: Sendable, Equatable {
        /// Calm, validate-then-inform header copy.
        public let header: String
        /// One-sentence hedge naming what the app can + can't carry.
        public let hedge: String
        /// Canonical portfolio resource list — already shown in Settings.
        public let resources: [CrisisResource]

        public init(header: String, hedge: String, resources: [CrisisResource]) {
            self.header = header
            self.hedge = hedge
            self.resources = resources
        }
    }

    /// Return a `Presentation` only when the signal warrants surfacing
    /// the resource card. `.calm` returns nil (no surface).
    public nonisolated static func presentation(for severity: DespairSignalDetector.Severity) -> Presentation? {
        switch severity {
        case .calm:
            return nil
        case .elevatedDistress:
            return Presentation(
                header: "Hey — what you wrote sounds heavy.",
                hedge: "If something hurts more than this app can hold, here are people trained to help.",
                resources: CrisisResources.all
            )
        case .elevatedCrisis:
            return Presentation(
                header: "What you wrote matters. You don't have to carry it alone.",
                hedge: "These people answer 24/7 — calling or texting is enough; you don't have to know what to say.",
                resources: CrisisResources.all
            )
        }
    }
}
