import SwiftUI
import Models
import Services
import SharedUI
import GameEngine
import AIMentor

/// Phase 1 placeholder root view. Real 4-tab `TabView` (Explore / Adventure /
/// Progress / Profile) lands in a follow-up PR per FEATURE_PLAN § SwiftUI Views.
///
/// Exposed `public` so the app shell (`Apps/MicrobeLab/MicrobeLab/MicrobeLabApp.swift`)
/// can swap from `ContentView` once the workspace adds Packages/Libraries.
/// See `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 1-2 for the GUI steps.
public struct AppRootView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "microscope")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(verbatim: "MicrobeLab")
                .font(.largeTitle.bold())
            Text("Phase 1 scaffolding shipped. Microscope coming next.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}
