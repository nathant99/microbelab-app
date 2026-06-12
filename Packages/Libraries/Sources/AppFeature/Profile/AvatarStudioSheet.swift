import SwiftUI
import Services
import ForgeAvatar
import ForgeModels
import ForgeSync

/// Sheet host for the shared `ForgeAvatar.AvatarStudioView(.lite)` per
/// `.claude/rules/forgekit.md` § Avatar Edit Authority.
///
/// **CRITICAL gotcha (R489)**: `AvatarStudioView` internally calls
/// `appGroupStore.setAvatar(_:editedAt:)` on Save, which throws
/// `AppGroupStoreError.forgeIDMissing` if no `ForgeID` was seeded. Apps that
/// don't otherwise use ForgeSync (XP / streaks / achievements via
/// AppGroupStore) MUST seed the identity before the editor opens. We do that
/// in `.task` so the user can't tap Save before the seed completes.
struct AvatarStudioSheet: View {
    let appGroupStore: AppGroupStore
    let catalog: AvatarAssetCatalog
    let displayName: String
    let onSaved: (AvatarConfig) -> Void
    let onCancelled: () -> Void

    @State private var initialConfig: AvatarConfig = .default
    @State private var baselineEditedAt: Date?
    @State private var didSeedIdentity = false

    var body: some View {
        AvatarStudioView(
            initialConfig: initialConfig,
            baselineEditedAt: baselineEditedAt,
            catalog: catalog,
            presentation: .lite,
            appGroupStore: appGroupStore,
            onSaved: onSaved,
            onCancelled: onCancelled
        )
        .task {
            await seedForgeIDAndLoadAvatar()
        }
    }

    private func seedForgeIDAndLoadAvatar() async {
        guard !didSeedIdentity else { return }
        didSeedIdentity = true
        let id = await appGroupStore.getOrCreateForgeID(displayName: displayName)
        if let current = await appGroupStore.currentForgeID() {
            if let avatar = current.avatar {
                initialConfig = avatar
            }
            baselineEditedAt = current.avatarEditedAt
        }
        DebugLog.lifecycle("AvatarStudioSheet — seeded ForgeID id=\(id.id.uuidString)")
    }
}
