//
//  FocusSession.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var habitID: UUID
    var habitName: String
    var habitEmoji: String
    var durationSeconds: Int
    var elapsedSeconds: Int
    var startedAt: Date
    var completedAt: Date?
    var isCompleted: Bool

    init(
        habit: Habit,
        durationSeconds: Int
    ) {
        self.id = UUID()
        self.habitID = habit.id
        self.habitName = habit.name
        self.habitEmoji = habit.emoji
        self.durationSeconds = durationSeconds
        self.elapsedSeconds = 0
        self.startedAt = Date()
        self.completedAt = nil
        self.isCompleted = false
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(durationSeconds), 1.0)
    }

    var remainingSeconds: Int {
        max(durationSeconds - elapsedSeconds, 0)
    }

    var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var formattedDuration: String {
        let m = durationSeconds / 60
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rm = m % 60
        return rm > 0 ? "\(h)h \(rm)m" : "\(h)h"
    }

    func markCompleted() {
        isCompleted = true
        completedAt = Date()
        elapsedSeconds = durationSeconds
    }
}
