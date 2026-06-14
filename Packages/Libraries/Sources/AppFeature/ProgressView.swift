import SwiftUI
import Models
import Services
import ForgeModels
import ForgeUI

/// Progress tab. XP / streak / discovered-microbe count + Phase 1
/// achievement gallery. Reads directly from the injected
/// `GamificationService` so XP awards land in the UI immediately.
public struct ProgressTabView: View {
    public let progress: PlayerProgressData
    public let totalMicrobes: Int
    @Bindable public var gamification: GamificationService
    /// Optional reflection store — when supplied, the session-summary
    /// sheet surfaces an "Add a reflection" affordance that routes
    /// through ForgeKit 0.99.0's `ReflectionPromptSheet`. Older call
    /// sites that pass nil simply omit the affordance (the existing
    /// "See you next time" dismiss stays the only CTA).
    public var reflectionStore: ReflectionEntryStore?
    @State private var showingSummary = false
    @State private var showingCertificate = false
    @State private var showingReflection = false

    public init(
        progress: PlayerProgressData,
        totalMicrobes: Int,
        gamification: GamificationService,
        reflectionStore: ReflectionEntryStore? = nil
    ) {
        self.progress = progress
        self.totalMicrobes = totalMicrobes
        self.gamification = gamification
        self.reflectionStore = reflectionStore
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statsCard
                    codexProgressCard
                    achievementsCard
                }
                .padding()
            }
            .navigationTitle(Text(verbatim: "Progress"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSummary = true
                    } label: {
                        Label("Wrap up today", systemImage: "sun.horizon")
                    }
                    .accessibilityHint("Open today's session summary")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingCertificate = true
                    } label: {
                        Label("Share my codex", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityHint("Preview a shareable codex certificate showing the microbes you've met")
                }
            }
            .sheet(isPresented: $showingSummary) {
                SessionSummarySheet(
                    summary: currentSummary,
                    onDismiss: { showingSummary = false },
                    onAddReflection: reflectionStore == nil ? nil : {
                        showingSummary = false
                        // Sequence the reflection sheet AFTER the
                        // summary dismisses so SwiftUI's sheet stack
                        // stays single-layer.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            showingReflection = true
                        }
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingCertificate) {
                CodexCertificateSheet(
                    certificate: currentCertificate,
                    onDismiss: { showingCertificate = false }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingReflection) {
                if let store = reflectionStore {
                    ReflectionPromptSheet(
                        config: MicrobeLabReflectionPrompts.sessionClose,
                        onComplete: { entry in
                            store.append(entry)
                            showingReflection = false
                        }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    /// Capture a frozen `CodexCertificate` snapshot at the moment the sheet presents.
    /// Future-session activity doesn't retroactively change a certificate the kid has
    /// shared.
    private var currentCertificate: CodexCertificate {
        CodexCertificate(
            displayName: progress.displayName,
            microbesDiscovered: progress.discoveredMicrobeIDs.count,
            microbesTotal: totalMicrobes,
            issuedAt: Date()
        )
    }

    /// Capture a frozen `SessionSummary` snapshot at the moment the sheet
    /// presents. The view never re-derives mid-display so the numbers
    /// don't shift while the kid is reading them.
    private var currentSummary: SessionSummary {
        SessionSummary(
            currentLevel: gamification.currentLevel,
            totalXP: gamification.totalXP,
            currentStreak: gamification.currentStreak,
            microbesDiscovered: progress.discoveredMicrobeIDs.count,
            achievementsEarned: gamification.earnedAchievementSlugs.count
        )
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: progress.displayName.isEmpty ? "Explorer" : progress.displayName)
                .font(.title2.bold())
            HStack(spacing: 24) {
                stat(label: "Level", value: "\(gamification.currentLevel)")
                stat(label: "XP", value: "\(gamification.totalXP)")
                stat(label: "Streak", value: "\(gamification.currentStreak)d")
            }
            SwiftUI.ProgressView(value: gamification.xpProgress)
                .tint(.accentColor)
                .accessibilityLabel("Level progress")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.12), in: .rect(cornerRadius: 16))
    }

    private var codexProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "Codex")
                .font(.headline)
            HStack {
                Text("\(progress.discoveredMicrobeIDs.count) / \(totalMicrobes) discovered")
                    .font(.subheadline)
                Spacer()
            }
            SwiftUI.ProgressView(value: codexFraction)
                .tint(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.12), in: .rect(cornerRadius: 16))
    }

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(verbatim: "Achievements")
                    .font(.headline)
                Spacer()
                Text(verbatim: "\(gamification.earnedAchievementSlugs.count) / \(MicrobeLabAchievements.phase1.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                ForEach(MicrobeLabAchievements.phase1, id: \.id) { definition in
                    achievementChip(definition)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.12), in: .rect(cornerRadius: 16))
    }

    private func achievementChip(_ definition: ForgeModels.AchievementDefinition) -> some View {
        let isEarned = gamification.earnedAchievementSlugs.contains(definition.id)
        return VStack(spacing: 4) {
            Image(systemName: definition.iconAssetName)
                .imageScale(.large)
                .foregroundStyle(isEarned ? .yellow : .secondary)
            Text(verbatim: definition.title)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(verbatim: "\(definition.xpValue) XP")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .opacity(isEarned ? 1.0 : 0.55)
        .accessibilityLabel(isEarned ? "\(definition.title) earned" : "\(definition.title) locked")
    }

    private var codexFraction: Double {
        guard totalMicrobes > 0 else { return 0 }
        return Double(progress.discoveredMicrobeIDs.count) / Double(totalMicrobes)
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
