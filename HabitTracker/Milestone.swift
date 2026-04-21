//
//  Milestone.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import Foundation
import SwiftData

enum MilestoneType: String, Codable {
    case streak      = "streak"
    case totalCount  = "totalCount"
    case goalReached = "goalReached"
    case custom      = "custom"
}

@Model
final class Milestone {
    var id: UUID
    var title: String
    var emoji: String
    var type: MilestoneType
    var targetValue: Int
    var habitID: UUID?
    var habitName: String?
    var isCustom: Bool
    var isReached: Bool
    var reachedAt: Date?
    var badgeID: UUID?            // linked badge when reached

    init(
        title: String,
        emoji: String,
        type: MilestoneType,
        targetValue: Int,
        habitID: UUID? = nil,
        habitName: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.type = type
        self.targetValue = targetValue
        self.habitID = habitID
        self.habitName = habitName
        self.isCustom = isCustom
        self.isReached = false
        self.reachedAt = nil
        self.badgeID = nil
    }

    func markReached() {
        guard !isReached else { return }
        isReached = true
        reachedAt = Date()
    }

    var progressDescription: String {
        switch type {
        case .streak:
            return "\(targetValue)-day streak"
        case .totalCount:
            return "\(targetValue) total check-ins"
        case .goalReached:
            return "Goal reached \(targetValue) times"
        case .custom:
            return title
        }
    }
}

// MARK: - Default milestones factory

enum DefaultMilestones {
    static func all() -> [Milestone] {
        [
            Milestone(title: "First Step",
                      emoji: "👶",
                      type: .totalCount,
                      targetValue: 1),
            Milestone(title: "Getting Started",
                      emoji: "🌱",
                      type: .totalCount,
                      targetValue: 7),
            Milestone(title: "One Month Strong",
                      emoji: "💪",
                      type: .totalCount,
                      targetValue: 30),
            Milestone(title: "Century Club",
                      emoji: "💯",
                      type: .totalCount,
                      targetValue: 100),
            Milestone(title: "7-Day Flow",
                      emoji: "🔥",
                      type: .streak,
                      targetValue: 7),
            Milestone(title: "Fortnight Focus",
                      emoji: "⚡️",
                      type: .streak,
                      targetValue: 14),
            Milestone(title: "30-Day Legend",
                      emoji: "🏆",
                      type: .streak,
                      targetValue: 30),
            Milestone(title: "Unstoppable",
                      emoji: "🚀",
                      type: .streak,
                      targetValue: 60),
            Milestone(title: "Goal Getter",
                      emoji: "🎯",
                      type: .goalReached,
                      targetValue: 1),
            Milestone(title: "Consistency Builder",
                      emoji: "🧱",
                      type: .goalReached,
                      targetValue: 30),
        ]
    }

    static func defaultBadges() -> [Badge] {
        [
            Badge(name: "First Step",
                  badgeDescription: "Complete a habit for the first time",
                  emoji: "👶",
                  condition: .firstCompletion),
            Badge(name: "7-Day Flow",
                  badgeDescription: "Maintain a 7-day streak",
                  emoji: "🔥",
                  condition: .streakDays,
                  conditionValue: 7),
            Badge(name: "30-Day Legend",
                  badgeDescription: "Maintain a 30-day streak",
                  emoji: "🏆",
                  condition: .streakDays,
                  conditionValue: 30),
            Badge(name: "Century Club",
                  badgeDescription: "Check in 100 times total",
                  emoji: "💯",
                  condition: .totalCheckIns,
                  conditionValue: 100),
            Badge(name: "Consistency Builder",
                  badgeDescription: "Reach your goal 30 times",
                  emoji: "🧱",
                  condition: .goalReached,
                  conditionValue: 30),
            Badge(name: "Unstoppable",
                  badgeDescription: "Maintain a 60-day streak",
                  emoji: "🚀",
                  condition: .streakDays,
                  conditionValue: 60),
        ]
    }
}
