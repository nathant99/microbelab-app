# MicrobeLab — Privacy Policy

_Last updated: 2026-06-12. Plain-language summary intended for kids + parents alike. The legal-register version that ships with the App Store listing inherits from this draft._

## The one-line version

MicrobeLab keeps everything on the device. We don't collect personal information, we don't sell anything to anyone, we don't show ads, and we don't share data with third parties.

## What we don't do

- We **don't ask for your name, email, address, phone number, or birthday**. The app uses a friendly display name you choose locally; we never see it.
- We **don't collect analytics**. No Firebase, no Mixpanel, no Amplitude, no Segment, no anonymous "telemetry" beacons.
- We **don't show ads**. There are no in-app purchases, either.
- We **don't share data with third parties**. There are no third-party SDKs that could ship data off-device on our behalf.
- We **don't use cloud sync for kid data**. Your progress, codex discoveries, achievements, streak, settings — all of it lives on the device.

## What lives on your device

- Your **progress + codex** (which microbes you've discovered, which achievements you've earned, your level + XP)
- Your **streak** (current + longest + last-active date) and the freezes you have available
- Your **settings** (sound / haptics / Reduce Motion / Reduce Transparency overrides, daily session cap, content gates, "Keep it gentle" toggle)
- Your **avatar look** (saved via Apple's on-device ForgeID; never leaves the device)
- Anonymous **retention counters** (Day-1 / Day-7 / Day-30 return signals — just counts, never an event log)

All of this stays on the device. If you delete the app, it's all gone.

## On-device AI (Vee + microbe cast)

MicrobeLab uses Apple's on-device FoundationModels framework to generate Socratic mentor cues + microbe fact cards. **The model runs entirely on your device** — your questions never leave the iPhone / iPad. Apple's privacy guarantees for FoundationModels apply.

When the model is unavailable (older devices, downloading state, low-power mode), the app falls back to hand-authored static content per `.claude/rules/foundationmodels.md`.

## Parents + COPPA

MicrobeLab is built for ages 9-14 with a deliberately conservative posture per the 2026 FTC COPPA amendments effective April 22, 2026:

- **No personal information is collected** — full stop. There's nothing to consent to, because there's nothing to share.
- **Parental gates** appear before content-comfort toggles (disease-story gate, "Keep it gentle" difficulty pin) + session-cap changes. The gates use the math-problem pattern per Apple's HIG.
- **Daily session cap** defaults to 30 minutes per portfolio convention. Parents can raise / lower / remove it from Settings after passing the math gate.
- **30-second parent handoff flow** runs before the kid's first session so a grown-up confirms content comfort + daily cap up front. The handoff persists nothing but a binary "I've completed this" flag.

If you'd like to delete everything the app has saved, deleting the app from your device clears every on-device store.

## Crisis resources

MicrobeLab surfaces a small crisis-resource card from Settings + (in future Phase 3 disease-story arcs) inline at trauma-adjacent surfaces. The three resources — 988 Suicide & Crisis Lifeline, Childhelp 1-800-422-4453, Crisis Text Line (Text HOME to 741741) — open the system phone / messages app via `tel:` / `sms:` URLs. **MicrobeLab never sends or stores anything related to a tap on those rows.** The deep-link hands off to the OS; we don't even see whether you tapped.

## Questions

Reach the studio at hello@spark-and-anvil.com. We answer parent + educator questions personally.

## Changes to this policy

If we ever change what data the app handles (we don't plan to — but if), the next app update will:

1. Bump the `Last updated` date at the top of this doc + the version surfaced in Settings → Privacy
2. Surface a one-time in-app notice describing the change in plain language before the next session

We will never reduce protections without surfacing the change first.
