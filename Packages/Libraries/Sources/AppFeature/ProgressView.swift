import SwiftUI
import Models

/// Progress tab. XP / streak / discovered-microbe count. Surfaces the same
/// data as ForgeKit's `ForgeXPBar` + `ForgeStreakBadge` but currently uses a
/// minimal native shape so the tab compiles standalone — ForgeKit wiring
/// lands when AvatarStudio integration arrives.
public struct ProgressTabView: View {
    public let progress: PlayerProgressData
    public let totalMicrobes: Int

    public init(progress: PlayerProgressData, totalMicrobes: Int) {
        self.progress = progress
        self.totalMicrobes = totalMicrobes
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statsCard
                    codexProgressCard
                }
                .padding()
            }
            .navigationTitle(Text(verbatim: "Progress"))
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: progress.displayName.isEmpty ? "Explorer" : progress.displayName)
                .font(.title2.bold())
            HStack(spacing: 24) {
                stat(label: "XP", value: "\(progress.totalXP)")
                stat(label: "Streak", value: "\(progress.currentStreak)d")
                stat(label: "Longest", value: "\(progress.longestStreak)d")
            }
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
