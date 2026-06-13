import SwiftUI
import Services
#if canImport(UIKit)
import UIKit
#endif

/// Sheet wrapper for `CodexCertificateView`. Surfaces the preview certificate + a
/// trauma-informed "Share" affordance (via `ShareLink`) + a "Maybe later" off-ramp.
/// `ImageRenderer` produces a PNG of the certificate at the moment the kid taps share;
/// the resulting `Image` ships through `ShareLink` so the system share sheet handles
/// Messages / Mail / AirDrop / Save Image routing without MicrobeLab touching any of
/// those surfaces.
///
/// Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Share-worthy moments" + trauma-
/// informed register: the sheet NEVER tries to drive sharing through engagement
/// pressure ("share to earn XP" / "your friends are sharing"); it surfaces the
/// certificate as a quiet "this is your record" moment that the kid controls.
public struct CodexCertificateSheet: View {
    public let certificate: CodexCertificate
    public let onDismiss: () -> Void

    public init(certificate: CodexCertificate, onDismiss: @escaping () -> Void) {
        self.certificate = certificate
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Your codex certificate")
                    .font(.title3.weight(.semibold))
                Text("This stays on your device unless you choose to share it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)

            CodexCertificateView(certificate: certificate)
                .shadow(radius: 6)

            VStack(spacing: 12) {
                shareButton
                    .accessibilityHint("Open the system share sheet so you can save or send the certificate.")
                Button("Maybe later") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Dismiss the certificate without sharing.")
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
    }

    /// Renders the certificate as an `Image` via `ImageRenderer`, then hands it to
    /// `ShareLink` so the system share sheet handles routing. The renderer runs on
    /// MainActor (UIKit / SwiftUI rendering requirement) and scales for crisp output on
    /// Retina displays per `.claude/rules/warnings.md` § `UIScreen.main` deprecation —
    /// uses `UITraitCollection.current.displayScale` on iOS.
    @MainActor
    @ViewBuilder
    private var shareButton: some View {
        if let image = renderedImage {
            ShareLink(
                item: image,
                preview: SharePreview(
                    "Codex certificate — \(certificate.headline)",
                    image: image
                )
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                onDismiss()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
            .accessibilityHint("Sharing isn't available right now.")
        }
    }

    /// Lazily-rendered `Image` wrapping a `UIImage` (iOS) or `NSImage` (macOS) PNG
    /// representation of `CodexCertificateView`. Returns nil when rendering fails on
    /// the current platform (graceful fallback for unit-test contexts / headless
    /// rendering).
    @MainActor
    private var renderedImage: Image? {
        #if canImport(UIKit)
        let renderer = ImageRenderer(content: CodexCertificateView(certificate: certificate))
        renderer.scale = UITraitCollection.current.displayScale
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
        #else
        return nil
        #endif
    }
}
