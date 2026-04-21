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
    @State private var showingOnboarding = !UserDefaults.standard.bool(
        forKey: "onboardingComplete"
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(theme.effectiveColorScheme)
                .tint(theme.accentColor)
                .fullScreenCover(isPresented: $showingOnboarding) {
                    OnboardingView(isPresented: $showingOnboarding)
                }
                .task {
//                    guard !notificationsRequested else { return }
//                    notificationsRequested = true
//                    _ = await NotificationManager.shared.requestPermission()
                    seedDefaultDataIfNeeded()
                }
        }
        .modelContainer(SharedStore.container)
    }
    
    @MainActor private func seedDefaultDataIfNeeded() {
        let key = "defaultMilestonesSeeded_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let ctx = SharedStore.container.mainContext
        for m in DefaultMilestones.all() { ctx.insert(m) }
        for b in DefaultMilestones.defaultBadges() { ctx.insert(b) }
        UserDefaults.standard.set(true, forKey: key)
    }
}


// MARK: - Migration

enum HabitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HabitSchemaV1.self, HabitSchemaV2.self, HabitSchemaV3.self,
         HabitSchemaV4.self, HabitSchemaV5.self, HabitSchemaV6.self]
    }
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: HabitSchemaV1.self, toVersion: HabitSchemaV2.self),
            .lightweight(fromVersion: HabitSchemaV2.self, toVersion: HabitSchemaV3.self),
            .lightweight(fromVersion: HabitSchemaV3.self, toVersion: HabitSchemaV4.self),
            .lightweight(fromVersion: HabitSchemaV4.self, toVersion: HabitSchemaV5.self),
            .lightweight(fromVersion: HabitSchemaV5.self, toVersion: HabitSchemaV6.self),
        ]
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

enum HabitSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [Habit.self, Tag.self] }
}

enum HabitSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] { [Habit.self, Tag.self, FocusSession.self] }
}

enum HabitSchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Habit.self, Tag.self, FocusSession.self,
         HabitGoal.self, Milestone.self, Badge.self]
    }
}

enum HabitSchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Habit.self, Tag.self, FocusSession.self,
         HabitGoal.self, Milestone.self, Badge.self]
    }
}
