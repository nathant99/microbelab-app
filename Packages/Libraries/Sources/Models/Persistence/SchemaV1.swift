import Foundation
import SwiftData

/// V1 schema. Per `.claude/rules/swiftdata.md` § Schema Versioning & Migration:
/// "Start with `VersionedSchema` from day one — even before first App Store
/// release."
///
/// **Pre-App Store**: do NOT add a new `VersionedSchema` for unreleased model
/// changes — extend V1 in place. A new schema version is only created for the
/// first App Store release that ships changes to existing model fields.
public enum SchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            PersistentMicrobeSession.self,
            PlayerProgress.self,
            EncounterLog.self,
            JournalEntry.self,
        ]
    }
}

/// V1-only migration plan. The shape lets us add V2 / V3 stages cleanly once
/// the first App Store release ships and we evolve the schema.
public enum MicrobeLabMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
