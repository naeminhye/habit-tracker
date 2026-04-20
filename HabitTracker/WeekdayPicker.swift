//
//  WeekdayPicker.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct WeekdayPicker: View {
    @Binding var selectedDays: [Int]

    // Calendar weekday: 1=Sun, 2=Mon, ... 7=Sat
    private let days: [(id: Int, short: String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"),
        (6, "Fri"), (7, "Sat"), (1, "Sun"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.id) { day in
                let isSelected = selectedDays.contains(day.id)
                Button {
                    toggleDay(day.id)
                } label: {
                    Text(day.short)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected
                                ? Color.accentColor
                                : Color.secondary.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }

        // Quick presets
        HStack(spacing: 8) {
            presetButton("Weekdays", days: [2, 3, 4, 5, 6])
            presetButton("Weekends", days: [1, 7])
            presetButton("Every day", days: [1, 2, 3, 4, 5, 6, 7])
        }
        .padding(.top, 4)
    }

    private func presetButton(_ label: String, days: [Int]) -> some View {
        let isActive = Set(selectedDays) == Set(days)
        return Button {
            selectedDays = days
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isActive
                        ? Color.accentColor.opacity(0.15)
                        : Color.secondary.opacity(0.08),
                    in: Capsule()
                )
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
        }
    }
}

