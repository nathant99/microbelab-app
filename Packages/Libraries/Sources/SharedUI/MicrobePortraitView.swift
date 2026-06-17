import SwiftUI
import Models

/// Canonical cast-member portrait surface — single rendering seam for the
/// 12-microbe cast across every consumer view (codex card, chapter reader
/// header, AI mentor turn-prefix portrait, future cast voicing UI). When
/// the cast-WebP at `cast_<slug>.webp` is bundled, it renders; otherwise
/// the SF-Symbol + role-color tint fallback renders so every consumer
/// surface has a stable affordance TODAY without blocking on the labsmith-
/// side cast portrait wave.
///
/// Per `Docs/FEATURE_PLAN.md` § 12-Character Microbe Cast (line 65), the
/// 12 WebPs are bundle-blocked on hub distribution. The placeholder
/// pathway is the de-risking seam: when the assets land in a single
/// labsmith asset wave, no consumer-side wiring needs to chase the
/// arrival — the `Bundle.module` lookup resolves and every consumer
/// surface picks up the asset simultaneously.
///
/// **Asset naming convention** (per `.claude/rules/forgekit.md` § "Cast
/// asset filename convention" + the trauma-gated chapter wave handoff at
/// `Docs/HANDOFF_FROM_LABSMITH_CHAPTER_ILLUSTRATIONS_TRAUMA_GATED_WAVE.md`):
/// the bundled WebP filename is `cast_<slug>.webp`. The `<slug>` matches
/// `MicrobeCharacter.slug` (e.g., `guard`, `lacto`, `net`, `photo`,
/// `spore`, `yeast`). Default bundle is `.main` (the app bundle) — when
/// the labsmith asset wave lands the WebPs in the app target's resources
/// they resolve. Callers MAY pass a different `Bundle` (e.g., a SharedUI
/// `.module` once `resources:` is declared) without changing the
/// rendering pathway.
///
/// **Trauma-informed posture**: undiscovered microbes render with the
/// `questionmark.circle` symbol + neutral gray tint regardless of the
/// microbe's actual role. The role-color cue (red for pathogenic, etc.)
/// surfaces ONLY after discovery — keeps the codex grid free of
/// pre-emptive "scary microbe!" framing for kids who haven't met the
/// character yet.
///
/// **Accessibility**: the view is decorative wrapper; consumers compose
/// the surrounding accessibility label (e.g., `MicrobeCodexCard`'s
/// `accessibilityElement(children: .combine)` already collapses this
/// view's label into the parent). When used standalone (e.g., chapter
/// reader header), pass `accessibilityLabel:` so the SF-Symbol fallback
/// emits a kid-friendly label.
public struct MicrobePortraitView: View {
    public let microbe: MicrobeCharacter
    public let isDiscovered: Bool
    public let bundle: Bundle

    public init(
        microbe: MicrobeCharacter,
        isDiscovered: Bool = true,
        bundle: Bundle = .main
    ) {
        self.microbe = microbe
        self.isDiscovered = isDiscovered
        self.bundle = bundle
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundFill)
            content
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if isDiscovered, let portrait = portraitImage {
            portrait
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Image(systemName: fallbackSymbolName)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(fallbackTint)
        }
    }

    /// Look up the bundled cast portrait. Returns `nil` when the WebP
    /// hasn't been distributed yet (the default state until the labsmith
    /// asset wave lands).
    private var portraitImage: Image? {
        let name = "cast_\(microbe.slug)"
        #if canImport(UIKit)
        guard let ui = UIImage(named: name, in: bundle, with: nil) else { return nil }
        return Image(uiImage: ui)
        #elseif canImport(AppKit)
        guard let ns = bundle.image(forResource: name) else { return nil }
        return Image(nsImage: ns)
        #else
        return nil
        #endif
    }

    private var backgroundFill: Color {
        if isDiscovered {
            return roleColor.opacity(0.12)
        }
        return Color.secondary.opacity(0.15)
    }

    private var fallbackSymbolName: String {
        // Apple's `microbe.circle.fill` is iOS 17+; absent on older
        // platforms but the deploy target is iOS 26 so it's safe here.
        // Undiscovered cards still render the neutral `questionmark` cue
        // per the trauma-informed posture above.
        isDiscovered ? "microbe.circle.fill" : "questionmark.circle"
    }

    private var fallbackTint: Color {
        isDiscovered ? roleColor : Color.secondary
    }

    private var roleColor: Color {
        switch microbe.role {
        case .beneficial: return .green
        case .neutral: return .gray
        case .opportunistic: return .orange
        case .pathogenic: return .red
        }
    }
}
