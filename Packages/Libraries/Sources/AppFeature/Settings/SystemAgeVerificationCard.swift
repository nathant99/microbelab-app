import SwiftUI
import Services
#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif
#if canImport(UIKit)
import UIKit
#endif

/// SwiftUI surface that drives the Declared Age Range system path. Wraps
/// Apple's `@Environment(\.requestAgeRange)` action + maps the response into
/// the app-side `AgeAssuranceService` state seam.
///
/// **Status (2026-06-17)**: actively wired. The card RENDERS in every build,
/// but the "Verify with Apple" button only enables when:
///
/// 1. The `com.apple.developer.declared-age-range` entitlement has been
///    provisioned via the target's Signing & Capabilities tab (probed at
///    runtime via `AgeAssuranceCapability.isDeclaredAgeRangeAvailable` — the
///    soft entitlement probe defined on `AgeAssuranceService`).
/// 2. The `DeclaredAgeRange` framework is importable at compile time
///    (gated by `#if canImport(DeclaredAgeRange)`).
///
/// When either condition fails, the card surfaces the static math-gate
/// fallback affordance (already in `ParentalGateView`). The capability
/// probe + framework import are decoupled so the build stays green on
/// platforms / SDKs that haven't yet shipped the framework.
///
/// Per `.claude/rules/age-assurance.md` § "Declared Age Range API
/// (iOS 26.2+)": receiving "Under 13" creates COPPA actual knowledge —
/// the result-mapping path in this card MUST flow through the parent
/// handoff flow (consent + record-keeping) before any downstream UI
/// surface reads the result. The current wiring just records the result;
/// downstream consent integration ships in a focused follow-up round.
///
/// Per the Xcode-managed file safety rule (canonical-invariant tier):
/// this PR cannot write the `.entitlements` file from disk. The
/// entitlement provisioning steps are documented in
/// `Docs/HANDOFF_TO_USER_DECLARED_AGE_RANGE_ENTITLEMENT.md`.
public struct SystemAgeVerificationCard: View {
    @Bindable public var service: AgeAssuranceService
    public let minimumAge: Int

    public init(service: AgeAssuranceService, minimumAge: Int = 13) {
        self.service = service
        self.minimumAge = minimumAge
    }

    @State private var inFlight: Bool = false
    @State private var lastError: String?

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusLine
            actionRow
            if let lastError {
                Text(verbatim: lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityHint("Last system age verification error")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusLine: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("System age verification")
                    .font(.headline)
                Text(verbatim: statusCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: service.isCapable ? "checkmark.shield" : "person.crop.circle.badge.questionmark")
                .foregroundStyle(service.isCapable ? .green : .secondary)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        #if canImport(DeclaredAgeRange) && canImport(UIKit)
        if service.isCapable {
            Button {
                Task { @MainActor in await verify() }
            } label: {
                if inFlight {
                    ProgressView().controlSize(.small)
                } else {
                    Label("Verify with Apple", systemImage: "person.crop.circle.badge.checkmark")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inFlight)
            .accessibilityHint("Asks Apple's age range system to confirm the kid meets the minimum age")
        } else {
            Text(verbatim: "Math gate available in the parental control surface.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        #else
        Text(verbatim: "DeclaredAgeRange framework unavailable in this build — falls back to math gate.")
            .font(.caption)
            .foregroundStyle(.secondary)
        #endif
    }

    private var statusCaption: String {
        switch service.result {
        case .notAttempted:
            return service.isCapable
                ? "Tap below to verify."
                : "Entitlement not provisioned — using math gate."
        case .systemVerified(let adult):
            return adult ? "Verified at minimum age." : "Verified below minimum age — content gated."
        case .systemDeclined:
            return "Declined — falling back to math gate."
        case .systemUnavailable:
            return "System path unavailable — math gate active."
        }
    }

    #if canImport(DeclaredAgeRange) && canImport(UIKit)
    /// Calls Apple's `AgeRangeService.shared.requestAgeRange(...)` via the
    /// UIKit-anchored singleton path + maps the response onto
    /// `AgeAssuranceResult`. The singleton path takes a `UIViewController`
    /// anchor (vs the SwiftUI `@Environment(\.requestAgeRange)` action which
    /// surfaces a Sendable issue under Swift 6 strict checking — the action
    /// value is MainActor-isolated but its `callAsFunction` is `@concurrent`,
    /// which trips the strict-Sendable check; the singleton path avoids the
    /// cross-isolation passthrough entirely).
    ///
    /// Per Apple's docs the system presents a sheet describing what info
    /// is being requested + asks the user to grant permission. Response
    /// surfaces either a `.sharing(range:)` case (with an age range whose
    /// `lowerBound` is `nil` when "Under 13") or a `.declinedSharing` case.
    ///
    /// The presenting view controller is grabbed from the key window's
    /// root VC. Falls through to `.systemUnavailable` when no foreground
    /// window can be found (e.g., during scene activation transitions).
    @MainActor
    private func verify() async {
        inFlight = true
        defer { inFlight = false }
        guard let vc = presentingViewController() else {
            service.recordResult(.systemUnavailable)
            lastError = "No presenting window — try again."
            return
        }
        do {
            let response = try await AgeRangeService.shared.requestAgeRange(
                ageGates: minimumAge,
                in: vc
            )
            switch response {
            case .sharing(let ageRange):
                // Per Apple's docs: `lowerBound == nil` → person is under
                // the lowest threshold (here: under `minimumAge`).
                let meetsGate = (ageRange.lowerBound ?? -1) >= minimumAge
                service.recordResult(.systemVerified(adult: meetsGate))
                lastError = nil
            case .declinedSharing:
                service.recordResult(.systemDeclined)
                lastError = nil
            @unknown default:
                service.recordResult(.systemUnavailable)
                lastError = nil
            }
        } catch AgeRangeService.Error.invalidRequest {
            service.recordResult(.systemUnavailable)
            lastError = "System rejected the request (invalid)."
        } catch AgeRangeService.Error.notAvailable {
            service.recordResult(.systemUnavailable)
            lastError = "System path unavailable on this device."
        } catch {
            service.recordResult(.systemUnavailable)
            lastError = "Verification failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func presentingViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
    #endif
}
