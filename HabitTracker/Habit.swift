import Foundation
import SwiftData
import SwiftUI

// MARK: - Tag Model

@Model
final class Tag {
    var id: UUID
    var label: String
    var colorHex: String

    init(label: String, colorHex: String = "007AFF") {
        self.id = UUID()
        self.label = label
        self.colorHex = colorHex
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Habit Model

@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var habitDescription: String
    var accentColorHex: String
    var frequency: Frequency
    var customDays: Int
    var reminderTime: Date?
    var completedDates: [Date]
    var cellDecorations: [String: String]
    var createdAt: Date
    var tags: [Tag]

    init(
        name: String,
        emoji: String = "⭐️",
        habitDescription: String = "",
        accentColorHex: String = "007AFF",
        frequency: Frequency = .daily,
        customDays: Int = 2,
        reminderTime: Date? = nil,
        tags: [Tag] = []
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.habitDescription = habitDescription
        self.accentColorHex = accentColorHex
        self.frequency = frequency
        self.customDays = customDays
        self.reminderTime = reminderTime
        self.completedDates = []
        self.cellDecorations = [:]
        self.createdAt = Date()
        self.tags = tags
    }

    // MARK: - Accent color

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    // MARK: - Completion

    var isCompletedToday: Bool {
        completedDates.contains { Calendar.current.isDateInToday($0) }
    }

    func isCompleted(on date: Date) -> Bool {
        completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }

    func toggleToday() {
        if isCompletedToday {
            completedDates.removeAll { Calendar.current.isDateInToday($0) }
        } else {
            completedDates.append(Date())
        }
    }

    func toggle(date: Date) {
        if isCompleted(on: date) {
            completedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
        } else {
            completedDates.append(date)
        }
    }

    // MARK: - Decoration

    func decoration(for date: Date) -> String? {
        cellDecorations[dateKey(date)]
    }

    func setDecoration(_ emoji: String?, for date: Date) {
        if let emoji {
            cellDecorations[dateKey(date)] = emoji
        } else {
            cellDecorations.removeValue(forKey: dateKey(date))
        }
    }

    private func dateKey(_ date: Date) -> String {
        let d = Calendar.current.startOfDay(for: date)
        return "\(d.timeIntervalSince1970)"
    }

    // MARK: - Streak

    var currentStreak: Int {
        var streak = 0
        var day = Calendar.current.startOfDay(for: Date())
        let cal = Calendar.current
        while completedDates.contains(where: { cal.isDate($0, inSameDayAs: day) }) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    // MARK: - Frequency

    var isDueToday: Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        switch frequency {
        case .daily:
            return true
        case .weekly:
            let weekday = cal.component(.weekday, from: createdAt)
            return cal.component(.weekday, from: today) == weekday
        case .monthly:
            let dom = cal.component(.day, from: createdAt)
            return cal.component(.day, from: today) == dom
        case .everyNDays:
            let daysSince = cal.dateComponents(
                [.day],
                from: cal.startOfDay(for: createdAt),
                to: today
            ).day ?? 0
            return customDays > 0 && daysSince % customDays == 0
        }
    }

    var frequencyLabel: String {
        switch frequency {
        case .daily:      return "Daily"
        case .weekly:     return "Weekly"
        case .monthly:    return "Monthly"
        case .everyNDays: return "Every \(customDays)d"
        }
    }
}

// MARK: - Frequency

enum Frequency: String, Codable, CaseIterable {
    case daily      = "daily"
    case weekly     = "weekly"
    case monthly    = "monthly"
    case everyNDays = "everyNDays"

    var displayName: String {
        switch self {
        case .daily:      return "Daily"
        case .weekly:     return "Weekly"
        case .monthly:    return "Monthly"
        case .everyNDays: return "Every N days"
        }
    }
}
