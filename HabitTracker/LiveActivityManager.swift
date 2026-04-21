//
//  LiveActivityManager.swift
//  HabitTracker
//
//  Created by BangChitty on 21/04/2026.
//

import ActivityKit
import SwiftUI

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var currentActivity: Activity<FocusActivityAttributes>? = nil

    // MARK: - Start

    func startActivity(habit: Habit, session: FocusSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }

        // End any existing activity first
        endActivity()

        let state = FocusActivityAttributes.ContentState(
            habitName: habit.name,
            habitEmoji: habit.emoji,
            elapsedSeconds: session.elapsedSeconds,
            durationSeconds: session.durationSeconds,
            isPaused: false,
            accentColorHex: habit.accentColorHex
        )

        let attributes = FocusActivityAttributes(habitID: habit.id.uuidString)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            print("✅ Live Activity started: \(currentActivity?.id ?? "nil")")
        } catch {
            print("❌ Live Activity failed: \(error)")
        }
    }

    // MARK: - Update

    func updateActivity(session: FocusSession, isPaused: Bool) {
        guard let activity = currentActivity else { return }

        let state = FocusActivityAttributes.ContentState(
            habitName: activity.attributes.habitID, // keep existing
            habitEmoji: "⏱️",
            elapsedSeconds: session.elapsedSeconds,
            durationSeconds: session.durationSeconds,
            isPaused: isPaused,
            accentColorHex: "1D9E75"
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // Better update with full habit info
    func update(habit: Habit, session: FocusSession, isPaused: Bool) {
        guard let activity = currentActivity else { return }

        let state = FocusActivityAttributes.ContentState(
            habitName: habit.name,
            habitEmoji: habit.emoji,
            elapsedSeconds: session.elapsedSeconds,
            durationSeconds: session.durationSeconds,
            isPaused: isPaused,
            accentColorHex: habit.accentColorHex
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // MARK: - End

    func endActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}

