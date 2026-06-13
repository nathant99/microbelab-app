import SwiftUI
import Services

/// Codex completion certificate surface. Renders the kid's `CodexCertificate` snapshot as
/// a self-contained card the kid can share via `ShareLink`. Per `Docs/FEATURE_PLAN.md`
/// § Delight & Polish → "Share-worthy moments" + trauma-informed register:
///
/// - **Discovery framing**: headline scales warmly with progress; subline never compares
///   the kid's count to anyone else's, never frames low counts as failure.
/// - **No PII in the shared image**: the kid's display name surfaces only if the parent
///   already filled it in (defaults to "Explorer" per `PlayerProgressData`).
/// - **Privacy posture**: counts stay on-device. Sharing produces a rendered PNG only —
///   no underlying analytics or per-microbe identity leaves the device.
///
/// The view is intentionally simple — a vertical card with a celebration badge, headline,
/// subline, progress chip, and issued-on footer. It's both the in-app preview AND the
/// rendered share surface, so the same view layout drives both UX and the PNG export.
public struct CodexCertificateView: View {
    public let certificate: CodexCertificate

    public init(certificate: CodexCertificate) {
        self.certificate = certificate
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "microbe")
                .font(.system(size: 64, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(heroColor)
                .accessibilityHidden(true)

            Text(certificate.headline)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(certificate.subline)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            progressChip

            Divider().padding(.horizontal)

            VStack(spacing: 2) {
                Text("MicrobeLab")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(certificate.issuedOnLabel())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if !certificate.displayName.isEmpty {
                    Text("For \(certificate.displayName)")
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
        .accessibilityLabel("\(certificate.headline). \(certificate.subline). \(certificate.issuedOnLabel()).")
    }

    private var progressChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .imageScale(.small)
                .foregroundStyle(heroColor)
            Text("\(certificate.microbesDiscovered) / \(certificate.microbesTotal) microbes")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(heroColor.opacity(0.12), in: Capsule())
    }

    /// Hero color `#33CCBB` (bio-luminescent teal-cyan) per
    /// `Docs/TECHNICAL_DESIGN.md` § Delight & Emotional Design. Inlined here so the view
    /// stays self-contained for the share-rendered PNG (no service dep graph required).
    private var heroColor: Color {
        Color(red: 0x33 / 255.0, green: 0xCC / 255.0, blue: 0xBB / 255.0)
    }
}
