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
    var selectedDays: [Int]
    var focusDurationMinutes: Int
    var deepFocusEnabled: Bool
    var goal: HabitGoal?
    var goalsReachedCount: Int
    var reminderTime: Date?
    var completedDates: [Date]
    var cellDecorations: [String: String]
    var createdAt: Date
    var startDate: Date
    var endDate: Date?
    var tags: [Tag]
    
    init(
        name: String,
        emoji: String = "⭐️",
        habitDescription: String = "",
        accentColorHex: String = "007AFF",
        frequency: Frequency = .daily,
        customDays: Int = 2,
        selectedDays: [Int] = [],
        focusDurationMinutes: Int = 0,
        deepFocusEnabled: Bool = false,
        goal: HabitGoal? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        reminderTime: Date? = nil
    ) {
        self.id                   = UUID()
        self.name                 = name
        self.emoji                = emoji
        self.habitDescription     = habitDescription
        self.accentColorHex       = accentColorHex
        self.frequency            = frequency
        self.customDays           = customDays
        self.selectedDays         = selectedDays
        self.focusDurationMinutes = focusDurationMinutes
        self.deepFocusEnabled     = deepFocusEnabled
        self.goal                 = goal
        self.goalsReachedCount    = 0
        self.startDate            = startDate
        self.endDate              = endDate
        self.reminderTime         = reminderTime
        self.completedDates       = []
        self.cellDecorations      = [:]
        self.createdAt            = Date()
        self.tags                 = []
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
            // Remove ALL completions from today
            completedDates.removeAll {
                Calendar.current.isDateInToday($0)
            }
            // Also clear today's decoration
            setDecoration(nil, for: Date())
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
        
        // Not started yet
        if cal.startOfDay(for: startDate) > today { return false }
        
        // Past end date
        if let end = endDate, cal.startOfDay(for: end) < today { return false }
        
        switch frequency {
        case .daily:
            return true
        case .weekly:
            let weekday = cal.component(.weekday, from: startDate)
            return cal.component(.weekday, from: today) == weekday
        case .monthly:
            let dom = cal.component(.day, from: startDate)
            return cal.component(.day, from: today) == dom
        case .everyNDays:
            let daysSince = cal.dateComponents(
                [.day],
                from: cal.startOfDay(for: startDate),
                to: today
            ).day ?? 0
            return customDays > 0 && daysSince % customDays == 0
        case .weekdays:
            let todayWeekday = cal.component(.weekday, from: today)
            return selectedDays.contains(todayWeekday)
        }
    }
    
    // Next active date after today
    var nextDueDate: Date? {
        let cal = Calendar.current
        var day = cal.startOfDay(
            for: cal.date(byAdding: .day, value: 1, to: Date())!
        )
        for _ in 0..<60 {
            let weekday = cal.component(.weekday, from: day)
            let matches: Bool
            switch frequency {
            case .daily:
                return day
            case .weekly:
                matches = cal.component(.weekday, from: startDate) == weekday
            case .monthly:
                matches = cal.component(.day, from: startDate)
                           == cal.component(.day, from: day)
            case .everyNDays:
                let diff = cal.dateComponents(
                    [.day],
                    from: cal.startOfDay(for: startDate),
                    to: day
                ).day ?? 0
                matches = customDays > 0 && diff % customDays == 0
            case .weekdays:
                matches = selectedDays.contains(weekday)
            }
            if matches { return day }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return nil
    }
    
    var frequencyLabel: String {
        switch frequency {
        case .daily:      return "Daily"
        case .weekly:     return "Weekly"
        case .monthly:    return "Monthly"
        case .everyNDays: return "Every \(customDays)d"
        case .weekdays:   return selectedDaysLabel
        }
    }
    
    private var selectedDaysLabel: String {
        let shorts = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let labels = selectedDays.sorted().compactMap { d in
            d > 0 && d < shorts.count ? shorts[d] : nil
        }
        if labels.isEmpty { return "No days" }
        if labels.count == 7 { return "Every day" }
        if selectedDays.sorted() == [2, 3, 4, 5, 6] { return "Weekdays" }
        if selectedDays.sorted() == [1, 7] { return "Weekends" }
        return labels.joined(separator: ", ")
    }
    
    var hasFocusTimer: Bool {
        focusDurationMinutes > 0
    }
    
    // MARK: - Goal progress
    
    var totalCompletions: Int {
        completedDates.count
    }
    
    var todayCompletionCount: Int {
        completedDates.filter { Calendar.current.isDateInToday($0) }.count
    }
    
    func progressTowardGoal(on date: Date = Date()) -> Double {
        guard let goal else { return isCompleted(on: date) ? 1.0 : 0.0 }
        switch goal.type {
        case .oncePer:
            return isCompleted(on: date) ? 1.0 : 0.0
        case .nTimes:
            let count = completedDates.filter {
                Calendar.current.isDate($0, inSameDayAs: date)
            }.count
            return min(Double(count) / Double(goal.targetCount), 1.0)
        case .amount:
            return goal.targetAmount > 0
            ? min(goal.currentAmount / goal.targetAmount, 1.0)
            : 0.0
        }
    }
    
    var isGoalMetToday: Bool {
        progressTowardGoal() >= 1.0
    }
    
    var goalProgressLabel: String {
        guard let goal else { return "" }
        switch goal.type {
        case .oncePer:
            return isCompletedToday ? "Done" : "Not done"
        case .nTimes:
            return "\(todayCompletionCount)/\(goal.targetCount)"
        case .amount:
            let cur = goal.currentAmount
            let tar = goal.targetAmount
            let fmt = { (v: Double) -> String in
                v.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(v)) : String(format: "%.1f", v)
            }
            return "\(fmt(cur))/\(fmt(tar)) \(goal.unit)"
        }
    }
    
}

// MARK: - Frequency

enum Frequency: String, Codable, CaseIterable {
    case daily      = "daily"
    case weekly     = "weekly"
    case monthly    = "monthly"
    case everyNDays = "everyNDays"
    case weekdays   = "weekdays"
    
    var displayName: String {
        switch self {
        case .daily:      return "Daily"
        case .weekly:     return "Weekly"
        case .monthly:    return "Monthly"
        case .everyNDays: return "Every N days"
        case .weekdays:   return "Days of week"
        }
    }
}
