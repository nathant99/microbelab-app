import SwiftUI
import Models
import Services
import SharedUI

/// Codex tab. Renders the 12-microbe grid; locked entries show "???" until
/// the kid discovers them via the microscope loop.
public struct MicrobeCodexView: View {
    private let catalog: MicrobeCatalogService
    @State private var discoveredIDs: Set<UUID>

    public init(catalog: MicrobeCatalogService, discoveredIDs: Set<UUID> = []) {
        self.catalog = catalog
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
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: 12)]
    }
}
