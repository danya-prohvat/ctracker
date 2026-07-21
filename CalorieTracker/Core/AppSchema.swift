import SwiftData

/// Schema v1 — the shape the app first ships with. Any change to a @Model
/// after release = a new `VersionedSchema` here + a stage in
/// `AppMigrationPlan`, never an in-place edit (CLAUDE.md rule).
enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Product.self, DiaryEntry.self, UserSettings.self]
    }
}

/// Single-version plan for now; future versions append their stages here.
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AppSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
