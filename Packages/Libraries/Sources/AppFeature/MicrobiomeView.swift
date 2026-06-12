import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine

/// Microbiome puzzle tab. Wraps `MicrobiomePuzzleScene` + feeding-mode picker
/// + antibiotic shock affordance. Hosts a NavigationStack so the innate-
/// immunity minigame is reachable as a sub-page (toolbar shield button).
public struct MicrobiomeView: View {
    @State private var scene: MicrobiomePuzzleScene
    @State private var feedingMode: FeedingMode = .balanced
    @State private var tickCount: Int = 0
    @State private var showingAntibioticPrompt = false
    @State private var showingImmuneGame = false

    public init(simulator: MicrobiomeSimulator) {
        let initial = MicrobiomePuzzleScene(
            size: CGSize(width: 400, height: 600),
            simulator: simulator
        )
        _scene = State(initialValue: initial)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea(edges: .horizontal)
                    .safeAreaInset(edge: .top, spacing: 8) {
                        headerRow
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                controlBar
                    .padding()
                    .background(.thinMaterial)
            }
            .alert("Apply antibiotic?", isPresented: $showingAntibioticPrompt) {
                Button("Cancel", role: .cancel) {}
                Button("Apply") {
                    scene.triggerAntibiotic()
                    DebugLog.state("MicrobiomeView antibiotic applied")
                }
            } message: {
                Text("Antibiotics knock back the microbiome for a few ticks. Watch your microbes recover.")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImmuneGame = true
                    } label: {
                        Label("Defense game", systemImage: "shield.lefthalf.filled")
                    }
                    .accessibilityHint("Open the innate immunity minigame")
                }
            }
            .navigationDestination(isPresented: $showingImmuneGame) {
                ImmuneGameView()
                    .navigationTitle("Defense")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text(verbatim: "Microbiome — Tick \(tickCount)")
                .font(.headline)
            Spacer()
        }
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            FeedingModePicker(selected: feedingMode) { mode in
                feedingMode = mode
                scene.setFeedingMode(mode)
            }
            HStack(spacing: 12) {
                Button("Tick") {
                    scene.advanceOneTick()
                    tickCount = scene.machine.state.tickCount
                }
                .buttonStyle(.glassProminent)

                Button("Antibiotic") {
                    showingAntibioticPrompt = true
                }
                .buttonStyle(.glass)

                Button("Undo") {
                    scene.undo()
                    tickCount = scene.machine.state.tickCount
                }
                .buttonStyle(.glass)
            }
        }
    }
}
