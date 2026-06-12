import SwiftUI
import Services

/// 30-second parent handoff per `Docs/FEATURE_PLAN.md` § Onboarding & Child
/// Safety. Captures preferences a grown-up should set before the kid sees the
/// 5-step `MicrobeLabOnboardingFlow`. Persists choices into `AppSettings` +
/// flips the `ParentHandoffStore.hasCompletedHandoff` flag on completion.
///
/// Pure SwiftUI; no external UI framework. The flow is deliberately small —
/// 4 screens, ≤ 1 decision each, ≤ 30 seconds end-to-end — so the parent
/// never feels asked to read a wall of text.
public struct ParentHandoffFlow: View {
    @State private var machine = ParentHandoffMachine()
    private let store: ParentHandoffStore
    private let settingsStore: AppSettingsStore
    private let onComplete: () -> Void

    public init(
        store: ParentHandoffStore,
        settingsStore: AppSettingsStore,
        onComplete: @escaping () -> Void
    ) {
        self.store = store
        self.settingsStore = settingsStore
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("ParentHandoffFlow.step.\(machine.currentStep.rawValue)")
            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .onAppear {
            DebugLog.lifecycle("ParentHandoffFlow onAppear step=\(machine.currentStep)")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch machine.currentStep {
        case .welcome:
            welcomeStep
        case .contentComfort:
            contentComfortStep
        case .sessionCap:
            sessionCapStep
        case .ready:
            readyStep
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        StepLayout(
            systemImage: "hand.wave.fill",
            title: "Hi grown-up",
            body: "Thirty seconds to set things up, then you can hand the device over. There's no account, no PII, no third-party SDKs."
        )
    }

    private var contentComfortStep: some View {
        StepLayout(
            systemImage: "shield.lefthalf.filled",
            title: "Disease stories",
            body: "MicrobeLab can include short, age-9-14 disease-story arcs in a later phase. They stay off until you opt in."
        ) {
            Toggle(isOn: $machine.allowsDiseaseStories) {
                Text("Allow disease story arcs")
                    .font(.callout.weight(.medium))
            }
            .toggleStyle(.switch)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .accessibilityHint("You can change this later in Settings.")
        }
    }

    private var sessionCapStep: some View {
        StepLayout(
            systemImage: "clock.fill",
            title: "Daily limit",
            body: "Pick the daily session cap. Default is 30 minutes per portfolio guidance — you can adjust later in Settings."
        ) {
            Picker(selection: $machine.dailyCapChoice) {
                ForEach(ParentDailyCap.allCases) { choice in
                    Text(verbatim: choice.displayName).tag(choice)
                }
            } label: {
                Text("Daily limit")
            }
            .pickerStyle(.segmented)
            .accessibilityHint("Pick the daily session length cap.")
        }
    }

    private var readyStep: some View {
        StepLayout(
            systemImage: "checkmark.seal.fill",
            title: "Ready!",
            body: "Hand the device to your kid. The next screens are written for ages 9–14 — they introduce the microscope and a beneficial microbe named Lacto."
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            if !machine.isFinalStep {
                Button("Skip — I'll set this later") {
                    machine.skip()
                    finalize()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("ParentHandoffFlow.skip")
            }
            Spacer()
            Button(machine.isFinalStep ? "Hand off" : "Next") {
                if machine.isFinalStep {
                    finalize()
                } else {
                    machine.advance()
                    DebugLog.lifecycle("ParentHandoffFlow advance → \(machine.currentStep)")
                }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("ParentHandoffFlow.primary")
        }
    }

    // MARK: - Persistence

    /// Apply the in-flight choices to `AppSettings` and flip the handoff
    /// flag. Skip + Hand-off both arrive here so the kid never sees the
    /// parent flow twice unless `ParentHandoffStore.reset()` is invoked.
    private func finalize() {
        var next = settingsStore.settings
        // Disease-story gate is INVERTED: machine.allowsDiseaseStories = true
        // means the gate is OFF (content allowed).
        next.diseaseStoryGateEnabled = !machine.allowsDiseaseStories
        next.dailySessionCap = machine.dailyCapChoice.toAppSettingsCap()
        settingsStore.save(next)
        store.markCompleted()
        DebugLog.lifecycle("ParentHandoffFlow finalize — allowsDisease=\(machine.allowsDiseaseStories) cap=\(machine.dailyCapChoice.rawValue)")
        onComplete()
    }
}

// MARK: - Shared step layout

private struct StepLayout<Decoration: View>: View {
    let systemImage: String
    let title: String
    let bodyText: String
    @ViewBuilder var decoration: () -> Decoration

    init(
        systemImage: String,
        title: String,
        body: String,
        @ViewBuilder decoration: @escaping () -> Decoration = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.title = title
        self.bodyText = body
        self.decoration = decoration
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(verbatim: title)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(verbatim: bodyText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            decoration()
            Spacer(minLength: 24)
        }
    }
}

// MARK: - Mapping

extension ParentDailyCap {
    /// Map the machine's view-layer choice to the canonical
    /// `Services.DailySessionCap` that the Settings tab + session-target
    /// service consume.
    func toAppSettingsCap() -> DailySessionCap {
        switch self {
        case .fifteenMinutes: return .fifteen
        case .thirtyMinutes: return .thirty
        case .fortyFiveMinutes: return .fortyFive
        case .sixtyMinutes: return .sixty
        case .unlimited: return .unlimited
        }
    }
}
