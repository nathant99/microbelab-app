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

    /// Shared `ParentalConsentService` instance. When non-nil + the
    /// parental gate has passed, the "For parents" section surfaces a
    /// "Parental consents" NavigationLink to `ParentalConsentManagerView`.
    /// Optional so legacy SettingsView call sites (preview, test) still
    /// compile without threading the service.
    private let consentService: ParentalConsentService?

    /// Shared `WeeklySummaryService` instance. When non-nil + the
    /// parental gate has passed + the snapshot is non-nil, the "For
    /// parents" section surfaces an opt-in toggle that orchestrates
    /// authorization + consent + scheduling.
    private let weeklySummaryService: WeeklySummaryService?

    /// Shared `PhaseBoundaryExplainerService` instance. When non-nil + the
    /// parental gate has passed, the "For parents" section surfaces a
    /// "Boundary explainers" NavigationLink to `PhaseBoundaryExplainerView`.
    /// Closes `Docs/FEATURE_PLAN.md` Phase 3 line 163 consumer-view half.
    private let phaseBoundaryExplainer: PhaseBoundaryExplainerService?

    /// Shared `ProgressionService` instance. Threaded through so the
    /// PhaseBoundaryExplainerView can compute per-note gate-open state.
    private let progressionService: ProgressionService?

    /// Shared `AgeAssuranceService` instance. When non-nil + the parental
    /// gate has passed, the "About" section surfaces the new
    /// `SystemAgeVerificationCard` — the actual system path driver behind
    /// the previously-passive `ageAssuranceCapabilityRow`. The card
    /// remains gated by `service.isCapable` so the entitlement probe
    /// continues to govern whether the "Verify with Apple" button is
    /// usable. Optional so existing previews / tests still compile.
    private let ageAssuranceService: AgeAssuranceService?

    public init(
        store: AppSettingsStore? = nil,
        progressReportSnapshot: ProgressReportSnapshot? = nil,
        consentService: ParentalConsentService? = nil,
        weeklySummaryService: WeeklySummaryService? = nil,
        phaseBoundaryExplainer: PhaseBoundaryExplainerService? = nil,
        progressionService: ProgressionService? = nil,
        ageAssuranceService: AgeAssuranceService? = nil
    ) {
        _store = State(initialValue: store ?? AppSettingsStore())
        self.progressReportSnapshot = progressReportSnapshot
        self.consentService = consentService
        self.weeklySummaryService = weeklySummaryService
        self.phaseBoundaryExplainer = phaseBoundaryExplainer
        self.progressionService = progressionService
        self.ageAssuranceService = ageAssuranceService
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
        if progressReportSnapshot != nil
            || consentService != nil
            || weeklySummaryService != nil
            || phaseBoundaryExplainer != nil {
            Section {
                if let snapshot = progressReportSnapshot {
                    progressReportRow(snapshot: snapshot)
                }
                if let service = consentService {
                    parentalConsentRow(service: service)
                }
                if let weekly = weeklySummaryService,
                   let consent = consentService,
                   let snapshot = progressReportSnapshot {
                    weeklySummaryRow(
                        weekly: weekly,
                        consent: consent,
                        snapshot: snapshot
                    )
                }
                if let explainer = phaseBoundaryExplainer {
                    phaseBoundaryExplainerRow(explainer: explainer)
                }
            } header: {
                Text("For parents")
            } footer: {
                Text("On-device only. The report covers session count, streak, XP, time, and the NGSS / NHES standards the Phase 1 kits address. Per-question detail stays local. Consents renew annually per the 2026 FTC COPPA Rule.")
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func phaseBoundaryExplainerRow(explainer: PhaseBoundaryExplainerService) -> some View {
        if hasPassedGate {
            NavigationLink {
                PhaseBoundaryExplainerView(
                    explainer: explainer,
                    progression: progressionService,
                    consent: consentService
                )
            } label: {
                Label("Boundary explainers", systemImage: "list.bullet.indent")
            }
            .accessibilityHint("Opens the parent-facing preview of what's about to land on your kid's surface")
        } else {
            HStack {
                Label("Boundary explainers", systemImage: "list.bullet.indent")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Confirm adult") {
                    showingGate = true
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private func progressReportRow(snapshot: ProgressReportSnapshot) -> some View {
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
    }

    @ViewBuilder
    private func weeklySummaryRow(
        weekly: WeeklySummaryService,
        consent: ParentalConsentService,
        snapshot: ProgressReportSnapshot
    ) -> some View {
        if hasPassedGate {
            let binding = Binding<Bool>(
                get: { store.settings.weeklySummaryNotificationEnabled },
                set: { newValue in
                    var next = store.settings
                    next.weeklySummaryNotificationEnabled = newValue
                    store.save(next)
                    Task {
                        if newValue {
                            // Grant consent if not already; the parent
                            // has explicitly opted in by toggling on.
                            if !consent.hasValidConsent(for: .weeklySummaryNotifications) {
                                consent.recordGrant(for: .weeklySummaryNotifications)
                            }
                            let granted = await weekly.requestAuthorization()
                            if granted {
                                await weekly.scheduleNextSummary(from: snapshot)
                            } else {
                                // System denied — flip the setting back so
                                // the row reflects the actual state.
                                var rollback = store.settings
                                rollback.weeklySummaryNotificationEnabled = false
                                store.save(rollback)
                            }
                        } else {
                            await weekly.cancel()
                            consent.revoke(.weeklySummaryNotifications)
                        }
                    }
                    DebugLog.state("SettingsView weekly summary toggle → \(newValue)")
                }
            )
            Toggle(isOn: binding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly summary")
                    Text("Saturday morning, on-device only. A quiet week is fine — no shame.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHint("Toggle the opt-in weekly summary notification")
        } else {
            HStack {
                Label("Weekly summary", systemImage: "bell")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Confirm adult") {
                    showingGate = true
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private func parentalConsentRow(service: ParentalConsentService) -> some View {
        if hasPassedGate {
            NavigationLink {
                ParentalConsentManagerView(service: service)
            } label: {
                Label("Parental consents", systemImage: "checkmark.seal")
            }
            .accessibilityHint("Opens the per-feature consent manager")
        } else {
            HStack {
                Label("Parental consents", systemImage: "checkmark.seal")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Confirm adult") {
                    showingGate = true
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderless)
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
            if let ageAssuranceService, hasPassedGate {
                SystemAgeVerificationCard(service: ageAssuranceService)
                    .accessibilityHint("System-path Declared Age Range verification — sits behind the parental gate")
            }
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
