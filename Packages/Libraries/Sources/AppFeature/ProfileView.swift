import SwiftUI

/// Profile tab. Placeholder for the eventual `ForgeAvatar.AvatarStudioView`
/// integration (per `.claude/rules/forgekit.md` § Avatar Edit Authority).
public struct ProfileView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text(verbatim: "Explorer")
                                .font(.headline)
                            Text("Tap to customize")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Settings") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("All settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle(Text(verbatim: "Profile"))
        }
    }
}
