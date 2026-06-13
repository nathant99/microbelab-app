import SwiftUI
import Services
import ForgeModels

/// Parent-facing progress report. Renders a sectioned summary derived from a
/// `ProgressReportSnapshot` that the caller (typically `AppRootView`) builds
/// from live services. The view itself is stateless beyond the captured
/// snapshot — no service refs, no cross-tab observation, no PII surface.
///
/// Per `.claude/rules/age-assurance.md` § Portfolio Status + `Docs/PRIVACY_POLICY.md`:
/// counts only, on-device only. The "Standards covered" section pins the 4
/// bundled question-kit standards from `ProgressReportService.phase1Standards`
/// so the parent surface stays in sync without runtime catalog scans.
public struct ProgressReportView: View {
    private let snapshot: ProgressReportSnapshot
    private let service: ProgressReportService

    public init(snapshot: ProgressReportSnapshot, service: ProgressReportService = ProgressReportService()) {
        self.snapshot = snapshot
        self.service = service
    }

    public var body: some View {
        Form {
            engagementSection
            standardsCoveredSection
            reportTextSection
            footerSection
        }
        .navigationTitle(Text(verbatim: "Progress report"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var engagementSection: some View {
        Section {
            statRow("Sessions", value: "\(snapshot.totalSessions)")
            statRow("Distinct days played", value: "\(snapshot.activeDays)")
            statRow("Current streak", value: "\(snapshot.currentStreak) day\(snapshot.currentStreak == 1 ? "" : "s")")
            statRow("Longest streak", value: "\(snapshot.longestStreak) day\(snapshot.longestStreak == 1 ? "" : "s")")
            statRow("Total XP", value: "\(snapshot.totalXP)")
            statRow("Activities completed", value: "\(snapshot.activitiesCompleted)")
            statRow("Total time", value: "\(snapshot.totalDurationMinutes) min")
        } header: {
            Text("Engagement")
        } footer: {
            Text("Counts only. No per-question data leaves the device.")
                .font(.caption)
        }
    }

    private var standardsCoveredSection: some View {
        Section {
            ForEach(ProgressReportService.phase1Standards, id: \.code) { standard in
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: standard.code)
                        .font(.subheadline.weight(.semibold))
                    Text(verbatim: standard.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Standards covered")
        } footer: {
            Text("Phase 1 question kits map to NGSS Middle School Life Science (MS-LS1-1/2/3 + MS-LS2-3) and National Health Education Standards 1 + 7.")
                .font(.caption)
        }
    }

    private var reportTextSection: some View {
        Section {
            Text(verbatim: service.parentReportText(for: snapshot))
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .accessibilityLabel("Parent conference report text")
        } header: {
            Text("Parent conference summary")
        } footer: {
            Text("Generated locally via ForgeReporting. Strengths + growth areas surface here once per-standard proficiency lands; today the summary covers engagement + recommendations.")
                .font(.caption)
        }
    }

    private var footerSection: some View {
        Section {
            Text("MicrobeLab keeps every progress signal on this device. Nothing here syncs to a server.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func statRow(_ label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(verbatim: value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#Preview {
    NavigationStack {
        ProgressReportView(snapshot: ProgressReportSnapshot(
            totalSessions: 14,
            totalDurationMinutes: 72,
            activitiesCompleted: 3,
            currentStreak: 4,
            longestStreak: 9,
            totalXP: 280,
            activeDays: 7
        ))
    }
}
