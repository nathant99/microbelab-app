import SwiftUI

/// Plain-language privacy policy surfaced from `SettingsView`. Mirrors
/// the canonical doc at `Docs/PRIVACY_POLICY.md` so the in-app surface
/// and the App Store listing surface stay aligned.
///
/// **Why inline copy not bundled Markdown**: a hard-coded Swift String
/// keeps the view self-contained (no Bundle.module resource processing,
/// no fallback for the read-failure path, no Markdown-parser surprises
/// in production). When the canonical doc changes, both copies update
/// together in the same PR.
///
/// Per `Docs/FEATURE_PLAN.md` § Onboarding & Child Safety →
/// "Privacy policy — Plain-language policy accessible from Settings and
/// App Store listing".
public struct PrivacyPolicyView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Last updated: 2026-06-12. Plain-language summary intended for kids + parents alike.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                section(title: "The one-line version") {
                    Text("MicrobeLab keeps everything on the device. We don't collect personal information, we don't sell anything to anyone, we don't show ads, and we don't share data with third parties.")
                }

                section(title: "What we don't do") {
                    bulletList([
                        "**No personal info.** We don't ask for your name, email, address, phone number, or birthday.",
                        "**No analytics.** No Firebase, no Mixpanel, no Amplitude. No anonymous telemetry beacons.",
                        "**No ads.** No in-app purchases either.",
                        "**No third-party SDKs.** Nothing on-device could ship data on our behalf.",
                        "**No cloud sync of kid data.** Progress, codex, achievements, streak, settings — all on-device."
                    ])
                }

                section(title: "What lives on your device") {
                    bulletList([
                        "**Progress + codex** — which microbes you've discovered, achievements, level + XP.",
                        "**Streak + freezes** — current / longest / last-active / mercy days.",
                        "**Settings** — sound / haptics / motion overrides / daily cap / content gates / Keep It Gentle.",
                        "**Avatar look** — saved via on-device ForgeID; never leaves the device.",
                        "**Retention counters** — Day-1 / Day-7 / Day-30 return signals as anonymous counts."
                    ])
                    Text("Delete the app and it's all gone.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                section(title: "On-device AI (Vee + microbe cast)") {
                    Text("MicrobeLab uses Apple's on-device FoundationModels framework for the Socratic mentor cues + microbe fact cards. The model runs entirely on your device — your questions never leave the iPhone or iPad. When the model is unavailable (older devices, downloading state, low-power mode), the app falls back to hand-authored static content.")
                }

                section(title: "Parents + COPPA") {
                    Text("Built for ages 9-14 with a conservative posture per the 2026 FTC COPPA amendments (effective April 22, 2026):")
                    bulletList([
                        "**No personal information is collected** — full stop. Nothing to consent to.",
                        "**Parental gates** sit in front of content-comfort + session-cap changes.",
                        "**Daily session cap** defaults to 30 minutes; parents can raise or remove it.",
                        "**30-second parent handoff** runs before the kid's first session."
                    ])
                }

                section(title: "Crisis resources") {
                    Text("The crisis-resource card in Settings opens the system phone / messages app via tel: / sms: URLs. MicrobeLab never sends or stores anything related to a tap on those rows — the OS handles the deep-link.")
                }

                section(title: "Questions") {
                    Text("Reach the studio at hello@spark-and-anvil.com. We answer parent + educator questions personally.")
                }

                section(title: "Changes to this policy") {
                    Text("Any change bumps the date at the top + surfaces a one-time in-app notice describing the change in plain language before the next session. We will never reduce protections without surfacing the change first.")
                }
            }
            .padding()
        }
        .navigationTitle(Text(verbatim: "Privacy policy"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
                .font(.callout)
                .foregroundStyle(.primary)
        }
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(.init(item))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
