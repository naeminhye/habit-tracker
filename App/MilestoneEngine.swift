//
//  MilestoneEngine.swift
//  HabitTracker
//
//  Created by JaceyNguyen on 20/04/2026.
//

import SwiftUI
import SwiftData

@MainActor
final class MilestoneEngine {
    static let shared = MilestoneEngine()
    private init() {}

    // Called every time a habit is toggled or progress updated
    func check(habit: Habit, context: ModelContext) -> [MilestoneUnlock] {
        var unlocks: [MilestoneUnlock] = []

        // Fetch all milestones
        let allMilestones = (try? context.fetch(
            FetchDescriptor<Milestone>()
        )) ?? []

        // Fetch all badges
        let allBadges = (try? context.fetch(
            FetchDescriptor<Badge>()
        )) ?? []

        for milestone in allMilestones {
            guard !milestone.isReached else { continue }

            // Check if this milestone applies to this habit or all habits
            if let mid = milestone.habitID, mid != habit.id { continue }

            let reached: Bool
            switch milestone.type {
            case .streak:
                reached = habit.currentStreak >= milestone.targetValue
            case .totalCount:
                reached = habit.totalCompletions >= milestone.targetValue
            case .goalReached:
                reached = habit.goalsReachedCount >= milestone.targetValue
            case .custom:
                reached = evaluateCustom(milestone: milestone, habit: habit)
            }

            if reached {
                milestone.markReached()

                // Find matching badge
                let badge = matchingBadge(
                    for: milestone,
                    in: allBadges,
                    habit: habit,
                    context: context
                )
                badge?.unlock()

                unlocks.append(MilestoneUnlock(
                    milestone: milestone,
                    badge: badge,
                    habitName: habit.name,
                    habitEmoji: habit.emoji
                ))
            }
        }

        // Update goalsReachedCount if goal just met
        if habit.isGoalMetToday {
            let alreadyCounted = habit.completedDates
                .filter { Calendar.current.isDateInToday($0) }
                .count == 1
            if alreadyCounted {
                habit.goalsReachedCount += 1
            }
        }

        return unlocks
    }

    // MARK: - Custom milestone evaluation

    private func evaluateCustom(milestone: Milestone, habit: Habit) -> Bool {
        // Custom milestones are totalCount-based by default
        habit.totalCompletions >= milestone.targetValue
    }

    // MARK: - Match badge to milestone

    private func matchingBadge(
        for milestone: Milestone,
        in badges: [Badge],
        habit: Habit,
        context: ModelContext
    ) -> Badge? {
        // Try to find existing unlocked badge matching condition
        switch milestone.type {
        case .streak:
            return badges.first {
                $0.condition == .streakDays &&
                $0.conditionValue == milestone.targetValue &&
                !$0.isUnlocked
            }
        case .totalCount:
            if milestone.targetValue == 1 {
                return badges.first {
                    $0.condition == .firstCompletion && !$0.isUnlocked
                }
            }
            return badges.first {
                $0.condition == .totalCheckIns &&
                $0.conditionValue == milestone.targetValue &&
                !$0.isUnlocked
            }
        case .goalReached:
            return badges.first {
                $0.condition == .goalReached &&
                $0.conditionValue <= milestone.targetValue &&
                !$0.isUnlocked
            }
        case .custom:
            // Create a custom badge on the fly
            let badge = Badge(
                name: milestone.title,
                badgeDescription: milestone.progressDescription,
                emoji: milestone.emoji,
                condition: .custom,
                conditionValue: milestone.targetValue,
                habitID: habit.id,
                habitName: habit.name
            )
            context.insert(badge)
            return badge
        }
    }
}

// MARK: - MilestoneUnlock (result type)

struct MilestoneUnlock: Identifiable {
    let id = UUID()
    let milestone: Milestone
    let badge: Badge?
    let habitName: String
    let habitEmoji: String
}
