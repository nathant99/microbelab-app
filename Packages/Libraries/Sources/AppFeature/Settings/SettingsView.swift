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

    public init(store: AppSettingsStore? = nil) {
        _store = State(initialValue: store ?? AppSettingsStore())
    }

    public var body: some View {
        Form {
            sensorySection
            contentGateSection
            sessionCapSection
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

    // MARK: - About

    private var footerSection: some View {
        Section("About") {
            Label("Privacy policy", systemImage: "hand.raised")
            Label("Acknowledgements", systemImage: "doc.text")
        }
        .accessibilityHint("Static placeholder rows — wired in a follow-up PR")
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
