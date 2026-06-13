import SwiftUI
import Services
import ForgeAvatar
import ForgeModels
import ForgeSync

/// Profile tab. Presents the canonical `ForgeAvatar.AvatarStudioView(.lite)`
/// per `.claude/rules/forgekit.md` § Avatar Edit Authority. The displayed
/// avatar refreshes whenever the sheet saves.
public struct ProfileView: View {
    @State private var appGroupStore = AppGroupStore()
    @State private var catalog = AvatarAssetCatalog(appBundles: [])
    @State private var currentAvatar: AvatarConfig = .default
    @State private var showStudio = false
    @State private var displayName = "Explorer"

    /// Optional engagement snapshot. When non-nil, `SettingsView` surfaces the
    /// parent-facing "Progress report" row behind the parental gate.
    private let progressReportSnapshot: ProgressReportSnapshot?

    public init(progressReportSnapshot: ProgressReportSnapshot? = nil) {
        self.progressReportSnapshot = progressReportSnapshot
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    Button {
                        showStudio = true
                    } label: {
                        HStack(spacing: 12) {
                            AvatarRenderer(config: currentAvatar, catalog: catalog, size: 56)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: displayName)
                                    .font(.headline)
                                Text("Tap to customize your avatar")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the avatar editor")
                }
                Section("Settings") {
                    NavigationLink {
                        SettingsView(progressReportSnapshot: progressReportSnapshot)
                    } label: {
                        Label("All settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle(Text(verbatim: "Profile"))
        }
        .sheet(isPresented: $showStudio) {
            AvatarStudioSheet(
                appGroupStore: appGroupStore,
                catalog: catalog,
                displayName: displayName,
                onSaved: { saved in
                    currentAvatar = saved
                    showStudio = false
                    DebugLog.state("ProfileView — avatar saved")
                },
                onCancelled: {
                    showStudio = false
                    DebugLog.state("ProfileView — avatar edit cancelled")
                }
            )
        }
        .task {
            await refreshAvatar()
        }
    }

    /// Pull the current avatar before showing the avatar tile so the player's
    /// existing look is visible on the profile row.
    private func refreshAvatar() async {
        if let id = await appGroupStore.currentForgeID() {
            if let avatar = id.avatar {
                currentAvatar = avatar
            }
            if !id.displayName.isEmpty {
                displayName = id.displayName
            }
        }
    }
}
