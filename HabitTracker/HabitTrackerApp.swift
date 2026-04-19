//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

@main
struct HabitTrackerApp: App {
    @State private var notificationsRequested = false
    @State private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(theme.current.colorScheme)
                .task {
                    guard !notificationsRequested else { return }
                    notificationsRequested = true
                    _ = await NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(SharedStore.container)
    }
}


// MARK: - Migration

enum HabitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HabitSchemaV1.self, HabitSchemaV2.self]
    }
    static var stages: [MigrationStage] {
        [MigrationStage.lightweight(
            fromVersion: HabitSchemaV1.self,
            toVersion: HabitSchemaV2.self
        )]
    }
}

enum HabitSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Habit.self] }
}

enum HabitSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Habit.self, Tag.self] }
}
