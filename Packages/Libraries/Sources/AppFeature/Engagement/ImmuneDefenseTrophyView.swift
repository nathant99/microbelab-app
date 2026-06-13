import SwiftUI
import Services

/// Immune-defense run trophy surface. Renders the kid's
/// `ImmuneDefenseTrophy` snapshot as a self-contained card the kid can share
/// via `ShareLink`. Per `Docs/FEATURE_PLAN.md` § Delight & Polish →
/// "Share-worthy moments" + trauma-informed register:
///
/// - **Recognition framing**: headline scales warmly with waves cleared; a
///   perfect run earns a distinct top-tier headline; subline never compares
///   the kid's score to anyone else's, never frames low counts as failure.
/// - **No PII in the shared image**: the kid's display name surfaces only
///   if the parent already filled it in (defaults to "Explorer" per
///   `PlayerProgressData`).
/// - **Privacy posture**: counts stay on-device. Sharing produces a
///   rendered PNG only — no underlying analytics or per-run identity
///   leaves the device.
///
/// The view mirrors `CodexCertificateView` (same card shape, same
/// hero-color register, same ImageRenderer-ready frame) so the kid's
/// share-worthy moments read as a coherent set.
public struct ImmuneDefenseTrophyView: View {
    public let trophy: ImmuneDefenseTrophy

    public init(trophy: ImmuneDefenseTrophy) {
        self.trophy = trophy
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 64, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(heroColor)
                .accessibilityHidden(true)

            Text(trophy.headline)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(trophy.subline)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            statChips

            Divider().padding(.horizontal)

            VStack(spacing: 2) {
                Text("MicrobeLab")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(trophy.issuedOnLabel())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if !trophy.displayName.isEmpty {
                    Text("For \(trophy.displayName)")
                        .font(.caption2.italic())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(24)
        .frame(width: 320, height: 460)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.background)
                .shadow(color: heroColor.opacity(0.18), radius: 14, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(heroColor.opacity(0.35), lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trophy.headline). \(trophy.subline). \(trophy.scoreLabel). \(trophy.issuedOnLabel()).")
    }

    private var statChips: some View {
        HStack(spacing: 12) {
            chip(systemImage: "wave.3.right", label: trophy.waveLabel)
            chip(systemImage: "star.fill", label: trophy.scoreLabel)
        }
    }

    private func chip(systemImage: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .imageScale(.small)
                .foregroundStyle(heroColor)
            Text(label)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(heroColor.opacity(0.12), in: Capsule())
    }

    /// Hero color `#33CCBB` (bio-luminescent teal-cyan) per
    /// `Docs/TECHNICAL_DESIGN.md` § Delight & Emotional Design. Inlined here
    /// so the view stays self-contained for the share-rendered PNG (no
    /// service dep graph required). Same color register as the
    /// `CodexCertificateView` so the share-worthy moments read as a set.
    private var heroColor: Color {
        Color(red: 0x33 / 255.0, green: 0xCC / 255.0, blue: 0xBB / 255.0)
    }
}
