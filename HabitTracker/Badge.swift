//
//  Badge.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import Foundation
import SwiftData

enum BadgeCondition: String, Codable {
    case firstCompletion  = "firstCompletion"
    case streakDays       = "streakDays"
    case totalCheckIns    = "totalCheckIns"
    case goalReached      = "goalReached"
    case custom           = "custom"
}

@Model
final class Badge {
    var id: UUID
    var name: String
    var badgeDescription: String
    var emoji: String
    var condition: BadgeCondition
    var conditionValue: Int       // e.g. 7 for 7-day streak
    var habitID: UUID?            // nil = applies to any habit
    var habitName: String?
    var unlockedAt: Date?
    var isUnlocked: Bool

    init(
        name: String,
        badgeDescription: String,
        emoji: String,
        condition: BadgeCondition,
        conditionValue: Int = 0,
        habitID: UUID? = nil,
        habitName: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.badgeDescription = badgeDescription
        self.emoji = emoji
        self.condition = condition
        self.conditionValue = conditionValue
        self.habitID = habitID
        self.habitName = habitName
        self.unlockedAt = nil
        self.isUnlocked = false
    }

    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
    }

    var lockedDescription: String {
        switch condition {
        case .firstCompletion:
            return "Complete a habit for the first time"
        case .streakDays:
            return "Maintain a \(conditionValue)-day streak"
        case .totalCheckIns:
            return "Check in \(conditionValue) times total"
        case .goalReached:
            return "Reach your goal \(conditionValue) times"
        case .custom:
            return badgeDescription
        }
    }
}
