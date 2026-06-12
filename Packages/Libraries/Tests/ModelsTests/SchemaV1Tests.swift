import Foundation
import Testing
@testable import Models

@Suite("SchemaV1")
@MainActor
struct SchemaV1Tests {
    @Test func versionIdentifierIs1_0_0() {
        let v = SchemaV1.versionIdentifier
        #expect(v.major == 1)
        #expect(v.minor == 0)
        #expect(v.patch == 0)
    }

    @Test func allFourModelsRegistered() {
        let typeNames = SchemaV1.models.map { String(describing: $0) }
        #expect(typeNames.contains("PersistentMicrobeSession"))
        #expect(typeNames.contains("PlayerProgress"))
        #expect(typeNames.contains("EncounterLog"))
        #expect(typeNames.contains("JournalEntry"))
    }

    @Test func migrationPlanReferencesV1() {
        // No stages yet — pre-App Store, schema is still being extended in place.
        #expect(MicrobeLabMigrationPlan.stages.isEmpty)
        let names = MicrobeLabMigrationPlan.schemas.map { String(describing: $0) }
        #expect(names.contains("SchemaV1"))
    }
}
