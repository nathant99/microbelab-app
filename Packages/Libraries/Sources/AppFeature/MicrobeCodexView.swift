import SwiftUI
import Models
import Services
import SharedUI
import ForgeCelebration

/// Codex tab. Renders the 12-microbe grid; locked entries show "???" until
/// the kid discovers them via the microscope loop. Hosts a NavigationStack
/// so the toolbar surfaces a quiz-kits entry point.
public struct MicrobeCodexView: View {
    private let catalog: MicrobeCatalogService
    private let kitService: QuestionKitService
    private let gamification: GamificationService?
    private let celebration: CelebrationCoordinator?
    private let sensory: SensoryPaletteCoordinator?
    @State private var discoveredIDs: Set<UUID>
    @State private var availableKits: [QuestionKit] = []
    @State private var presentedKit: QuestionKit?
    @State private var knowledgeGraph: MicrobeKnowledgeGraph?

    public init(
        catalog: MicrobeCatalogService,
        kitService: QuestionKitService = QuestionKitService(),
        discoveredIDs: Set<UUID> = [],
        gamification: GamificationService? = nil,
        celebration: CelebrationCoordinator? = nil,
        sensory: SensoryPaletteCoordinator? = nil
    ) {
        self.catalog = catalog
        self.kitService = kitService
        self.gamification = gamification
        self.celebration = celebration
        self.sensory = sensory
        _discoveredIDs = State(initialValue: discoveredIDs)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(catalog.microbes) { microbe in
                        MicrobeCodexCard(
                            microbe: microbe,
                            isDiscovered: discoveredIDs.contains(microbe.id),
                            livesNearDisplayNames: livesNearDisplayNames(for: microbe)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(Text(verbatim: "Codex"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    quizMenu
                }
            }
            .onAppear {
                if availableKits.isEmpty {
                    availableKits = kitService.loadAllPhase1Kits()
                }
                if knowledgeGraph == nil {
                    // Build once per view lifetime; the catalog is bundled
                    // + immutable so we don't need to rebuild on discovery.
                    knowledgeGraph = MicrobeKnowledgeGraph(microbes: catalog.microbes)
                    DebugLog.lifecycle("MicrobeCodexView built ecology graph: \(knowledgeGraph?.nodeCount ?? 0) nodes, \(knowledgeGraph?.edgeCount ?? 0) edges")
                }
            }
            .sheet(item: $presentedKit) { kit in
                NavigationStack {
                    QuizView(kit: kit, gamification: gamification, celebration: celebration, sensory: sensory)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { presentedKit = nil }
                            }
                        }
                }
            }
        }
    }

    private var quizMenu: some View {
        Menu {
            if availableKits.isEmpty {
                Text("No kits available")
            } else {
                ForEach(availableKits) { kit in
                    Button {
                        presentedKit = kit
                    } label: {
                        Label("Kit \(kit.kitNumber): \(kit.title)", systemImage: "questionmark.circle")
                    }
                }
            }
        } label: {
            Label("Quizzes", systemImage: "questionmark.circle")
        }
        .accessibilityHint("Browse question kits")
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: 12)]
    }

    /// Returns the names of ecology neighbors to surface on a discovered
    /// card. Filters the graph's neighbors to the kid's discovered set so
    /// "Lives near" only references microbes they've actually met.
    /// Returns an empty array for undiscovered cards (the card hides the
    /// line itself based on `isDiscovered`).
    private func livesNearDisplayNames(for microbe: MicrobeCharacter) -> [String] {
        guard discoveredIDs.contains(microbe.id), let graph = knowledgeGraph else { return [] }
        let related = graph.related(to: microbe, limit: 4)
        let discoveredNeighbors = related.filter { discoveredIDs.contains($0.id) }
        // Cap to 2 display names so the card stays scannable.
        return Array(discoveredNeighbors.prefix(2).map(\.displayName))
    }
}
