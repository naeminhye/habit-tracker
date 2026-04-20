//
//  StreakStripView.swift
//  HabitTracker
//
//  Created by JaceyNguyen on 20/04/2026.
//

import SwiftUI
import SwiftData

struct StreakStripView: View {
    let habits: [Habit]

    // Last 7 days ending today
    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
    }

    // Was at least 1 habit (or goal) completed on this date?
    private func wasActiveOn(_ date: Date) -> Bool {
        habits.contains { habit in
            if let goal = habit.goal {
                // Goal-based: check if goal was met
                switch goal.type {
                case .oncePer:
                    return habit.isCompleted(on: date)
                case .nTimes:
                    let count = habit.completedDates.filter {
                        Calendar.current.isDate($0, inSameDayAs: date)
                    }.count
                    return count >= goal.targetCount
                case .amount:
                    return habit.isCompleted(on: date)
                }
            }
            return habit.isCompleted(on: date)
        }
    }

    // Is this day part of the current streak?
    private func isStreaking(on date: Date) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Only days up to today can be part of streak
        guard date <= today else { return false }

        // Walk back from today — if any day breaks, stop
        var check = today
        while check >= date {
            if !wasActiveOn(check) { return false }
            if cal.isDate(check, inSameDayAs: date) { return true }
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        return false
    }

    // Did the streak break before this day?
    private func isBreakDay(_ date: Date) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard date < today else { return false }

        // Not active on this day
        guard !wasActiveOn(date) else { return false }

        // Next day must be active (streak continues after this break)
        let nextDay = cal.date(byAdding: .day, value: 1, to: date)!
        guard wasActiveOn(nextDay) else { return false }

        // The day BEFORE this one must also have been active
        // — meaning a real streak existed before it broke here
        let prevDay = cal.date(byAdding: .day, value: -1, to: date)!
        return wasActiveOn(prevDay)
    }
    
    private var currentStreak: Int {
        var streak = 0
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        while wasActiveOn(day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            // Days strip
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    DayStreakCell(
                        date: day,
                        isActive: wasActiveOn(day),
                        isToday: Calendar.current.isDateInToday(day),
                        isStreaking: isStreaking(on: day),
                        isFrozen: isBreakDay(day)
                    )
                }
            }

            // Motivational message
            if currentStreak > 0 {
                streakMessage
            }
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
    }

    // MARK: - Streak message

    private var streakMessage: some View {
        let message = streakMotivation
        return HStack(spacing: DSSpacing.sm) {
            Text(message.emoji)
                .font(.system(size: 16))
            Text(message.text)
                .font(DSFont.bodyBold(13))
                .foregroundStyle(ThemeManager.shared.accentColor)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(
            ThemeManager.shared.accentColor.opacity(0.08),
            in: RoundedRectangle(cornerRadius: DSRadius.sm)
        )
    }

    private var streakMotivation: (emoji: String, text: String) {
        switch currentStreak {
        case 1:      return ("🌱", "Great start! Come back tomorrow.")
        case 2...4:  return ("⚡️", "Building momentum! Keep it up.")
        case 5...6:  return ("🔥", "Almost a week! Don't stop now.")
        case 7:      return ("🔥", "What a streak! Keep it going every day.")
        case 8...13: return ("💪", "You're on fire! \(currentStreak) days strong.")
        case 14:     return ("🏆", "Two weeks! You're unstoppable.")
        case 15...29: return ("🚀", "\(currentStreak) days! Keep the streak alive.")
        case 30...:  return ("👑", "\(currentStreak) days — you're a legend!")
        default:     return ("💫", "Start your streak today!")
        }
    }
}

// MARK: - DayStreakCell

struct DayStreakCell: View {
    let date: Date
    let isActive: Bool
    let isToday: Bool
    let isStreaking: Bool
    let isFrozen: Bool

    private var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private var isFuture: Bool {
        date > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 6) {
            // Day label
            Text(dayLabel)
                .font(DSFont.capsLabel(10))
                .foregroundStyle(isToday
                    ? ThemeManager.shared.accentColor
                    : Color.dsLabel)
                .kerning(0.3)

            // Circle with icon
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(circleBorder, lineWidth: isToday ? 2 : 1)
                    )

                if isFrozen {
                    // Frozen fire (Duolingo style)
                    Text("🧊")
                        .font(.system(size: 18))
                } else if isActive {
                    if isToday {
                        // Today + active = flame
                        Text("🔥")
                            .font(.system(size: 18))
                    } else {
                        // Past + active = checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else if isFuture {
                    // Future = empty
                    EmptyView()
                } else {
                    // Past + missed = nothing
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(isFuture ? 0.3 : 1.0)
    }

    private var circleFill: Color {
        if isFrozen { return Color(hex: "C8E8F8") }
        if isActive && isToday { return ThemeManager.shared.accentColor }
        if isActive { return ThemeManager.shared.accentColor }
        if isToday { return Color.clear }
        return Color.dsBorder.opacity(0.4)
    }

    private var circleBorder: Color {
        if isFrozen { return Color(hex: "7EC8E3") }
        if isToday && !isActive {
            return ThemeManager.shared.accentColor
        }
        return Color.clear
    }
}
