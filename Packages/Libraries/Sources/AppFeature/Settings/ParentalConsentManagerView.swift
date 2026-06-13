import SwiftUI
import Services

/// Parent-facing surface for granting + reviewing + revoking per-feature
/// consent records. Reached from `SettingsView`'s "For parents" section
/// once the parental gate has passed. Per
/// `.claude/rules/age-assurance.md` § 2026 FTC COPPA Rule Amendments:
/// separate verifiable parental consent is now required per data-sharing
/// / external-link class; this view surfaces one row per
/// `ParentalConsentKind` with a Toggle that grants or revokes.
///
/// Trauma-informed posture: the view never frames a revoke as
/// "denied"; consents simply disappear (the corresponding feature
/// gates close). The annual re-consent prompt reads as a calm
/// reconfirm, not as "your consent expired".
public struct ParentalConsentManagerView: View {
    /// MainActor service that persists records + answers
    /// `hasValidConsent(for:)` queries. Passed in so the view doesn't
    /// instantiate its own store + drift from `AppRootView`'s shared
    /// instance.
    private let service: ParentalConsentService

    public init(service: ParentalConsentService) {
        self.service = service
    }

    public var body: some View {
        Form {
            Section {
                ForEach(ParentalConsentKind.allCases) { kind in
                    consentRow(kind: kind)
                }
            } header: {
                Text("Consents")
            } footer: {
                Text("Each consent renews annually per the 2026 FTC COPPA Rule. A grown-up can revoke any consent at any time; the corresponding feature simply turns off.")
                    .font(.caption)
            }

            let expired = service.expiredRecords()
            if !expired.isEmpty {
                Section {
                    ForEach(expired) { record in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.kind.displayName)
                                Text("Last reviewed \(record.grantedAt, format: .dateTime.month().day().year())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundStyle(.orange)
                        }
                        .accessibilityHint("Reconfirm this consent")
                        .onTapGesture {
                            service.recordGrant(for: record.kind)
                        }
                    }
                } header: {
                    Text("Needs reconfirm")
                } footer: {
                    Text("Tap a row to refresh consent for another year.")
                        .font(.caption)
                }
            }
        }
        .navigationTitle(Text(verbatim: "Parental consents"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func consentRow(kind: ParentalConsentKind) -> some View {
        let binding = Binding<Bool>(
            get: { service.hasValidConsent(for: kind) },
            set: { newValue in
                if newValue {
                    service.recordGrant(for: kind)
                } else {
                    service.revoke(kind)
                }
            }
        )
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.displayName)
                Text(kind.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityHint(service.hasValidConsent(for: kind) ? "Revoke consent" : "Grant consent")
    }
}
