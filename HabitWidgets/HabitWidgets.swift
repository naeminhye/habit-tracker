//
//  HabitWidgets.swift
//  HabitWidgets
//
//  Created by BangChitty on 19/04/2026.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnapshot]
}

struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let isCompleted: Bool
    let streak: Int
}

// MARK: - Provider

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: .now, habits: [
            HabitSnapshot(id: UUID(), name: "Drink water", emoji: "💧", isCompleted: true,  streak: 5),
            HabitSnapshot(id: UUID(), name: "Read",        emoji: "📚", isCompleted: false, streak: 2),
            HabitSnapshot(id: UUID(), name: "Exercise",    emoji: "🏃", isCompleted: false, streak: 0),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let e = entry()
        // Refresh at midnight so "today" resets correctly
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )
        completion(Timeline(entries: [e], policy: .after(midnight)))
    }

    private func entry() -> HabitEntry {
        let context = ModelContext(SharedStore.container)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        let snapshots = habits.map {
            HabitSnapshot(
                id: $0.id,
                name: $0.name,
                emoji: $0.emoji,
                isCompleted: $0.isCompletedToday,
                streak: $0.currentStreak
            )
        }
        return HabitEntry(date: .now, habits: snapshots)
    }
}

// MARK: - Widget Views

struct HomeWidgetView: View {
    let entry: HabitEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  smallView
        case .systemMedium: mediumView
        default:            mediumView
        }
    }

    // Small: progress ring + count
    private var smallView: some View {
        let done  = entry.habits.filter(\.isCompleted).count
        let total = entry.habits.count
        let progress = total > 0 ? Double(done) / Double(total) : 0

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(done)")
                        .font(.title2.bold())
                    Text("of \(total)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            Text("Today")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // Medium: list of habits
    private var mediumView: some View {
        let visible = Array(entry.habits.prefix(4))

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                let done = entry.habits.filter(\.isCompleted).count
                Text("\(done)/\(entry.habits.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            if visible.isEmpty {
                Spacer()
                Text("No habits yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(visible) { habit in
                    HStack(spacing: 10) {
                        Text(habit.isCompleted ? "✅" : habit.emoji)
                            .font(.body)
                        Text(habit.name)
                            .font(.subheadline)
                            .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                            .strikethrough(habit.isCompleted, color: .secondary)
                        Spacer()
                        if habit.streak > 0 {
                            Text("🔥\(habit.streak)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Widget View

struct LockScreenWidgetView: View {
    let entry: HabitEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let done  = entry.habits.filter(\.isCompleted).count
        let total = entry.habits.count
        let progress = total > 0 ? Double(done) / Double(total) : 0
        let bestStreak = entry.habits.map(\.streak).max() ?? 0

        switch family {
        case .accessoryCircular:
            // Progress ring for lock screen
            ZStack {
                Gauge(value: progress) {
                    Text("habits")
                } currentValueLabel: {
                    Text("\(done)")
                        .font(.body.bold())
                }
                .gaugeStyle(.accessoryCircular)
            }

        case .accessoryRectangular:
            // Compact habit list
            VStack(alignment: .leading, spacing: 2) {
                Text("Habits · \(done)/\(total) done")
                    .font(.headline)
                ForEach(entry.habits.prefix(2)) { habit in
                    Text("\(habit.isCompleted ? "✓" : "○") \(habit.emoji) \(habit.name)")
                        .font(.caption)
                        .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                }
            }

        case .accessoryInline:
            // One-line summary
            if bestStreak > 0 {
                Text("🔥\(bestStreak) streak · \(done)/\(total) today")
            } else {
                Text("Habits · \(done)/\(total) done today")
            }

        default:
            Text("\(done)/\(total)")
        }
    }
}

// MARK: - Widget Definitions

struct HabitHomeWidget: Widget {
    let kind = "HabitHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Tracker")
        .description("See today's habits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HabitLockScreenWidget: Widget {
    let kind = "HabitLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Status")
        .description("Quick habit progress on your lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Widget Bundle

@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitHomeWidget()
        HabitLockScreenWidget()
        // Live Activity is registered automatically
        // via ActivityKit — no explicit registration needed
    }
}
