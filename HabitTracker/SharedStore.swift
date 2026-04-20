//
//  SharedStore.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftData
import Foundation

enum SharedStore {
    static let appGroupID = "group.com.bangchitty.habittracker"
    
    static var container: ModelContainer = {
        let schema = Schema([
            Habit.self, Tag.self, FocusSession.self,
            HabitGoal.self, Milestone.self, Badge.self
        ])
        
        guard let baseURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return createFallback(schema: schema)
        }
        
        let url = baseURL.appendingPathComponent("habits.store")
        
        do {
            let config = ModelConfiguration(
                schema: schema,
                url: url,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: config)  // ← no migrationPlan
        } catch {
            print("❌ SwiftData error: \(error)")
            let fm = FileManager.default
            for suffix in ["", "-wal", "-shm"] {
                try? fm.removeItem(atPath: url.path + suffix)
            }
            do {
                let config = ModelConfiguration(
                    schema: schema,
                    url: url,
                    cloudKitDatabase: .none
                )
                return try ModelContainer(for: schema, configurations: config)
            } catch {
                print("❌ Recovery failed: \(error)")
                return createFallback(schema: schema)
            }
        }
    }()
    
    private static func createFallback(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        return try! ModelContainer(for: schema, configurations: config)
    }
}
