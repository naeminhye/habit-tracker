//
//  MonthCalendarView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

struct MonthCalendarView: View {
    @Query var habits: [Habit]
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date? = nil
    @State private var decoratingHabit: HabitDatePair? = nil

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            calendarGrid
                .padding(.horizontal, 8)
            Spacer(minLength: 0)
        }
        .sheet(item: $decoratingHabit) { pair in
            DecorationPickerView(date: pair.date, habit: pair.habit)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Month header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    displayedMonth = Calendar.current.date(
                        byAdding: .month, value: -1, to: displayedMonth
                    )!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
                    .padding(8)
            }

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35)) {
                    displayedMonth = Calendar.current.date(
                        byAdding: .month, value: 1, to: displayedMonth
                    )!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .padding(8)
            }
            .disabled(Calendar.current.isDate(displayedMonth, equalTo: Calendar.current.startOfMonth(for: Date()), toGranularity: .month))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        habits: habits,
                        isToday: Calendar.current.isDateInToday(day),
                        isSelected: selectedDate.map {
                            Calendar.current.isDate($0, inSameDayAs: day)
                        } ?? false,
                        onTap: {
                            withAnimation(.spring(response: 0.2)) {
                                if let sel = selectedDate,
                                   Calendar.current.isDate(sel, inSameDayAs: day) {
                                    selectedDate = nil
                                } else {
                                    selectedDate = day
                                }
                            }
                        },
                        onDecorateTap: { habit in
                            guard Calendar.current.isDateInToday(day) else { return }
                            decoratingHabit = HabitDatePair(habit: habit, date: day)
                        }
                    )
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Days calculation

    private func daysInMonth() -> [Date?] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: displayedMonth)!
        let firstWeekday = cal.component(.weekday, from: displayedMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            let date = cal.date(byAdding: .day, value: day - 1, to: displayedMonth)!
            days.append(date)
        }
        // Pad to complete last row
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - HabitDatePair (sheet item)

struct HabitDatePair: Identifiable {
    let id = UUID()
    let habit: Habit
    let date: Date
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let habits: [Habit]
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDecorateTap: (Habit) -> Void

    private var completedHabits: [Habit] {
        habits.filter { $0.isCompleted(on: date) }
    }

    private var isFuture: Bool {
        date > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 2) {
            // Day number
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 26, height: 26)
                } else if isSelected {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 26, height: 26)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundStyle(
                        isToday ? .white :
                        isFuture ? Color.secondary.opacity(0.4) : .primary
                    )
            }

            // Sticker row — up to 3 habits shown
            if completedHabits.isEmpty {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 20)
            } else {
                HStack(spacing: 1) {
                    ForEach(completedHabits.prefix(3)) { habit in
                        let deco = habit.decoration(for: date)
                        Text(deco ?? habit.emoji)
                            .font(.system(size: completedHabits.count > 2 ? 10 : 13))
                            .onTapGesture {
                                onDecorateTap(habit)
                            }
                    }
                    if completedHabits.count > 3 {
                        Text("+\(completedHabits.count - 3)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .onTapGesture { onTap() }
        .opacity(isFuture ? 0.4 : 1.0)
    }
}

// MARK: - Calendar extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
}
