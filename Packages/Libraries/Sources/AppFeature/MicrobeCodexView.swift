import SwiftUI
import Models
import Services
import SharedUI

/// Codex tab. Renders the 12-microbe grid; locked entries show "???" until
/// the kid discovers them via the microscope loop. Hosts a NavigationStack
/// so the toolbar surfaces a quiz-kits entry point.
public struct MicrobeCodexView: View {
    private let catalog: MicrobeCatalogService
    private let kitService: QuestionKitService
    private let gamification: GamificationService?
    @State private var discoveredIDs: Set<UUID>
    @State private var availableKits: [QuestionKit] = []
    @State private var presentedKit: QuestionKit?

    public init(
        catalog: MicrobeCatalogService,
        kitService: QuestionKitService = QuestionKitService(),
        discoveredIDs: Set<UUID> = [],
        gamification: GamificationService? = nil
    ) {
        self.catalog = catalog
        self.kitService = kitService
        self.gamification = gamification
        _discoveredIDs = State(initialValue: discoveredIDs)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(catalog.microbes) { microbe in
                        MicrobeCodexCard(microbe: microbe, isDiscovered: discoveredIDs.contains(microbe.id))
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
            }
            .sheet(item: $presentedKit) { kit in
                NavigationStack {
                    QuizView(kit: kit, gamification: gamification)
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
}
