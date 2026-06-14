import Foundation
import ForgeModels
import ForgeUI

/// Canonical MicrobeLab `ReflectionPromptConfig` catalog. Defines the
/// session-close reflection surface presented from
/// `SessionSummarySheet`'s "Add a reflection" affordance per the
/// ForgeKit 0.99.0 `ReflectionPromptModifier` contract.
///
/// **Why text + emoji + skip only** (no voice / drawing): voice + drawing
/// modalities require `NSMicrophoneUsageDescription` + PencilKit
/// availability respectively. Per `.claude/rules/xcode-agent-safety.md`
/// the agent cannot author `Info.plist` from disk; surfacing those
/// modalities would need entitlement provisioning via
/// `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md`. The text + emoji + skip
/// triad is sufficient for the v1 reflection surface and matches the
/// kid's expectation (quick acknowledgement, not a journal-rich-media
/// session).
///
/// **Trauma-informed posture** (per
/// `.claude/rules/trauma-informed-content.md` + the COVID-trauma-sensitive
/// register in `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design
/// Posture): the prompt copy frames reflection as warm noticing
/// ("What's one thing the microbes showed you today?") rather than
/// performance review ("What did you learn?" / "What was hardest?").
/// The `.skip` off-ramp is required by `ReflectionPromptConfig.init`
/// precondition so the kid can always close the sheet without
/// committing to an entry — never feeling trapped, never feeling like
/// skipping is a loss.
///
/// **Privacy posture**: `parentVisible = false`. The kid's reflection
/// stays in their on-device journal; the parent dashboard surfaces it
/// only when a future round adds a per-prompt opt-in via
/// `ParentalConsentKind` extension. v1 stays kid-only on-device so the
/// reflection feels like a private notebook, not a graded artifact.
public enum MicrobeLabReflectionPrompts {
    /// Stable app-identifier used by every config so the entries
    /// `appIdentifier` field decodes cleanly across catalog
    /// reorganizations.
    public static let appIdentifier = "com.microbelab.app"

    /// Canonical session-close reflection prompt. One question + the
    /// three trauma-safe modalities (text / emoji / skip).
    public static let sessionClose = ReflectionPromptConfig(
        id: "microbelab.reflection.sessionClose",
        questions: [
            "What's one thing the microbes showed you today?"
        ],
        allowedModalities: [.text, .emoji, .skip],
        appIdentifier: appIdentifier,
        kitNumber: nil,
        parentVisible: false
    )
}
