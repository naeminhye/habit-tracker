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
        let schema = Schema([Habit.self, Tag.self])   // ← add Tag
        let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            .appendingPathComponent("habits.store")
        let config = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .automatic
        )
        return try! ModelContainer(for: schema, configurations: config)
    }()
}
