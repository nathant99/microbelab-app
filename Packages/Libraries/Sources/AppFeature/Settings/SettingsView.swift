import SwiftUI
import Services

/// Settings surface with a parental-gate wall. Per
/// `.claude/rules/age-assurance.md`, toggles that affect data sharing or
/// content gates sit behind the gate; sensory toggles (sound, haptics,
/// motion / transparency overrides) are kid-accessible so a parent can
/// pre-configure without having to come back.
public struct SettingsView: View {
    @State private var store: AppSettingsStore
    @State private var hasPassedGate: Bool = false
    @State private var showingGate: Bool = false

    /// Optional snapshot of the kid's engagement signals. When non-nil + the
    /// parental gate has passed, the "For parents" section surfaces a
    /// "Progress report" NavigationLink to `ProgressReportView`. Wired via
    /// `AppRootView` → `ProfileView` → here so the snapshot reflects live
    /// state at the moment Settings opens.
    private let progressReportSnapshot: ProgressReportSnapshot?

    public init(store: AppSettingsStore? = nil, progressReportSnapshot: ProgressReportSnapshot? = nil) {
        _store = State(initialValue: store ?? AppSettingsStore())
        self.progressReportSnapshot = progressReportSnapshot
    }

    public var body: some View {
        NavigationStack {
            settingsForm
        }
    }

    private var settingsForm: some View {
        Form {
            sensorySection
            contentGateSection
            sessionCapSection
            forParentsSection
            CrisisResourceCard()
            footerSection
        }
        .navigationTitle(Text(verbatim: "Settings"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingGate) {
            ParentalGateView(
                onPassed: {
                    hasPassedGate = true
                    showingGate = false
                    DebugLog.permission("SettingsView parental gate passed")
                },
                onCancel: {
                    showingGate = false
                    DebugLog.permission("SettingsView parental gate cancelled")
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Sensory

    private var sensorySection: some View {
        Section("Sensory") {
            Toggle(isOn: bindingForBool(\.soundEffectsEnabled)) {
                Label("Sound effects", systemImage: "speaker.wave.2")
            }
            Toggle(isOn: bindingForBool(\.hapticsEnabled)) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: bindingForBool(\.forceReduceMotion)) {
                Label("Reduce Motion", systemImage: "figure.walk.motion")
            }
            Toggle(isOn: bindingForBool(\.forceReduceTransparency)) {
                Label("Reduce Transparency", systemImage: "rectangle.checkered")
            }
        }
    }

    // MARK: - Content gates (parent-gated)

    private var contentGateSection: some View {
        Section {
            Toggle(isOn: bindingForBool(\.diseaseStoryGateEnabled)) {
                Label("Disease story gate", systemImage: "shield.lefthalf.filled")
                    .accessibilityHint(hasPassedGate ? "Toggle the disease story gate" : "Confirm adult first")
            }
            .disabled(!hasPassedGate)
            Toggle(isOn: bindingForBool(\.simplifyChallenge)) {
                Label("Keep it gentle", systemImage: "leaf")
                    .accessibilityHint(hasPassedGate ? "Pin the experience to the gentlest difficulty" : "Confirm adult first")
            }
            .disabled(!hasPassedGate)
        } header: {
            Text("Content gates")
        } footer: {
            if hasPassedGate {
                Text("Adult-confirmed. Disease story gate toggles Phase 3+ arcs. \"Keep it gentle\" keeps the immune game + microbiome puzzle at their easiest setting forever.")
                    .font(.caption)
            } else {
                HStack {
                    Text("Adult-only toggles.")
                        .font(.caption)
                    Spacer()
                    Button("Confirm adult") {
                        showingGate = true
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    // MARK: - Session cap (parent-gated)

    private var sessionCapSection: some View {
        Section {
            Picker(selection: bindingForCap()) {
                ForEach(DailySessionCap.allCases) { cap in
                    Text(verbatim: cap.displayName).tag(cap)
                }
            } label: {
                Label("Daily limit", systemImage: "clock")
            }
            .pickerStyle(.menu)
            .disabled(!hasPassedGate)
        } header: {
            Text("Session limits")
        } footer: {
            Text("Default 30 minutes per portfolio convention. A grown-up can raise or remove this from this menu after confirming.")
                .font(.caption)
        }
    }

    // MARK: - For parents (gated)

    /// Parent-facing surfaces. Today: progress report (standards-mapped
    /// engagement summary via ForgeReporting). Future: weekly summary opt-in,
    /// classroom-mode toggles, COPPA consent records. Gated behind the same
    /// parental gate as content + session-cap toggles per
    /// `.claude/rules/age-assurance.md` § 2026 FTC COPPA Rule Amendments.
    @ViewBuilder
    private var forParentsSection: some View {
        if let snapshot = progressReportSnapshot {
            Section {
                if hasPassedGate {
                    NavigationLink {
                        ProgressReportView(snapshot: snapshot)
                    } label: {
                        Label("Progress report", systemImage: "chart.bar.doc.horizontal")
                    }
                    .accessibilityHint("Opens the standards-mapped engagement summary")
                } else {
                    HStack {
                        Label("Progress report", systemImage: "chart.bar.doc.horizontal")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Confirm adult") {
                            showingGate = true
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("For parents")
            } footer: {
                Text("On-device only. The report covers session count, streak, XP, time, and the NGSS / NHES standards the Phase 1 kits address. Per-question detail stays local.")
                    .font(.caption)
            }
        }
    }

    // MARK: - About

    private var footerSection: some View {
        Section("About") {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy policy", systemImage: "hand.raised")
            }
            .accessibilityHint("Opens the plain-language privacy policy")
            ageAssuranceCapabilityRow
            Label("Acknowledgements", systemImage: "doc.text")
                .foregroundStyle(.secondary)
                .accessibilityHint("Placeholder — wired in a follow-up PR")
        }
    }

    /// Passive readout of the Declared Age Range entitlement state. Driven
    /// off `AgeAssuranceCapability.isDeclaredAgeRangeAvailable`. Per
    /// `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § Declared Age Range API
    /// entitlement, the entitlement is added via the target's Signing &
    /// Capabilities tab; the agent cannot write entitlements files from
    /// disk. The row is informational only — once provisioned, a follow-up
    /// PR wires `ForgeAccessibility.ForgeSystemAgeGate` into the parent
    /// handoff flow.
    @ViewBuilder
    private var ageAssuranceCapabilityRow: some View {
        let isCapable = AgeAssuranceCapability.isDeclaredAgeRangeAvailable
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("Age verification")
                Text(verbatim: isCapable ? "Declared Age Range API ready" : "Math gate — Apple gate pending entitlement")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: isCapable ? "checkmark.shield" : "person.crop.circle.badge.questionmark")
                .foregroundStyle(isCapable ? .green : .secondary)
        }
        .accessibilityHint("Shows whether Apple's Declared Age Range API is wired for this build")
    }

    // MARK: - Bindings

    private func bindingForBool(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { newValue in
                var next = store.settings
                next[keyPath: keyPath] = newValue
                store.save(next)
                DebugLog.state("SettingsView toggle \(keyPath) → \(newValue)")
            }
        )
    }

    private func bindingForCap() -> Binding<DailySessionCap> {
        Binding(
            get: { store.settings.dailySessionCap },
            set: { newValue in
                var next = store.settings
                next.dailySessionCap = newValue
                store.save(next)
                DebugLog.state("SettingsView session cap → \(newValue.rawValue)")
            }
        )
    }
}
