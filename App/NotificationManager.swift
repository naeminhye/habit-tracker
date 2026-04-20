//
//  NotificationManager.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import UserNotifications
import SwiftUI

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Schedule

    func schedule(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) Time for: \(habit.name)"
        content.body = habit.currentStreak > 0
            ? "Keep your \(habit.currentStreak)-day streak alive! 🔥"
            : "Start building your streak today!"
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: habit.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Failed to schedule: \(error)") }
        }
    }

    // MARK: - Cancel

    func cancel(for habit: Habit) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
    }

    // MARK: - Reschedule all

    func rescheduleAll(habits: [Habit]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for habit in habits where habit.reminderTime != nil {
            schedule(for: habit)
        }
    }
    
    // MARK: - Milestone notification 
    func scheduleMilestoneNotification(unlock: MilestoneUnlock) {
        let content = UNMutableNotificationContent()
        content.title = "\(unlock.milestone.emoji) \(unlock.milestone.title)"
        if let badge = unlock.badge {
            content.body = "You unlocked the \(badge.name) badge! 🏅"
        } else {
            content.body = "Milestone reached on \(unlock.habitEmoji) \(unlock.habitName)!"
        }
        content.sound = .defaultRingtone

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone-\(unlock.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
