//
//  ProgressView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

// MARK: - View mode

enum ProgressViewMode {
    case month
    case habits
}

// MARK: - HabitProgressView

struct HabitProgressView: View {
    @Query var habits: [Habit]
    @State private var viewMode: ProgressViewMode = .month
    @State private var shareSnapshot: UIImage? = nil
    @State private var showingShare = false
    @State private var theme = ThemeManager.shared
    @State private var showingShareProgress = false

    var body: some View {
        NavigationStack {
            Group {
                if viewMode == .month {
                    MonthCalendarView()
                } else {
                    habitHeatmapView
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                // View mode switcher — top left
                ToolbarItem(placement: .navigationBarLeading) {
                    viewModePicker
                }
                // Share button — top right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingShareProgress = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let img = shareSnapshot {
                    ShareSheet(image: img)
                }
            }
            .sheet(isPresented: $showingShareProgress) {
                ShareProgressView()
            }
        }
    }

    // MARK: - View mode picker

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            modeButton(mode: .month, icon: "calendar")
            modeButton(mode: .habits, icon: "chart.bar.fill")
        }
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private func modeButton(mode: ProgressViewMode, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    viewMode == mode
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 7)
                )
                .foregroundStyle(
                    viewMode == mode ? Color.accentColor : Color.secondary
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Habit heatmap view

    private var habitHeatmapView: some View {
        ScrollView {
            VStack(spacing: 16) {
                overallStatsCard
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(habits) { habit in
                    HabitProgressCard(habit: habit)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Overall stats card

    private var overallStatsCard: some View {
        let best = habits.map(\.currentStreak).max() ?? 0
        let totalDone = habits.filter(\.isCompletedToday).count

        return HStack(spacing: 0) {
            statCell(value: "\(totalDone)/\(habits.count)", label: "Today")
            Divider().frame(height: 40)
            statCell(value: "\(best)🔥", label: "Best streak")
            Divider().frame(height: 40)
            statCell(value: "\(habits.count)", label: "Habits")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Share / Snapshot

    @MainActor
    private func takeSnapshot() {
        let view = snapshotView
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        if let img = renderer.uiImage {
            shareSnapshot = img
            showingShare = true
        }
    }

    @ViewBuilder
    private var snapshotView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("My Habit Progress")
                    .font(.title2.bold())
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if viewMode == .month {
                MonthCalendarView()
                    .frame(height: 420)
            } else {
                ForEach(habits.prefix(4)) { habit in
                    HabitProgressCard(habit: habit)
                }
            }

            HStack {
                Spacer()
                Text("Made with HabitTracker")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .frame(width: 390)
    }
}

// MARK: - IdentifiableDate

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

// MARK: - HabitProgressCard

struct HabitProgressCard: View {
    @Bindable var habit: Habit
    @State private var decoratingDate: IdentifiableDate? = nil
    @State private var theme = ThemeManager.shared

    private let columns = 7
    private let weeks = 5

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<(columns * weeks)).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            weekdayLabels
            heatmapGrid
            completionBar
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(item: $decoratingDate) { item in
            DecorationPickerView(date: item.date, habit: habit)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(habit.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.body.bold())
                if !habit.habitDescription.isEmpty {
                    Text(habit.habitDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(habit.frequencyLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                    .font(.body.bold())
                    .foregroundStyle(streakColor)
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weekday labels

    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Heatmap grid

    private var heatmapGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columns),
            spacing: 4
        ) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                cellView(for: day, index: index)
            }
        }
    }

    @ViewBuilder
    private func cellView(for day: Date, index: Int) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day)
        let isFuture = day > cal.startOfDay(for: Date())
        let isCompleted = habit.isCompleted(on: day)
        let decoration = habit.decoration(for: day)

        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(cellColor(completed: isCompleted, future: isFuture, index: index))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            isToday ? Color.accentColor : Color.clear,
                            lineWidth: 1.5
                        )
                )

            if let deco = decoration {
                Text(deco).font(.system(size: 10))
            } else if isCompleted {
                Text(habit.emoji).font(.system(size: 8)).opacity(0.6)
            }
        }
        // Today only: tap to toggle, long-press to decorate
        .onTapGesture {
            guard isToday else { return }
            withAnimation(.spring(response: 0.25)) {
                habit.toggle(date: day)
            }
        }
        .onLongPressGesture {
            guard isToday && isCompleted else { return }
            decoratingDate = IdentifiableDate(date: day)
        }
        // Past days: show lock hint
        .overlay(alignment: .center) {
            if !isToday && !isFuture && isCompleted {
                EmptyView()
            }
        }
        .opacity(isFuture ? 0.3 : 1.0)
    }

    // MARK: - Completion bar

    private var completionBar: some View {
        let rate = completionRate
        return VStack(spacing: 4) {
            HStack {
                Text("\(Int(rate * 100))% completion (last 35 days)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            ProgressView(value: rate)
                .tint(rateColor(rate))
        }
    }

    // MARK: - Helpers

    private func cellColor(completed: Bool, future: Bool, index: Int) -> Color {
        if future   { return Color.secondary.opacity(0.08) }
        guard completed else { return Color.secondary.opacity(0.15) }
        if theme.current == .pride {
            return theme.prideColor(at: index).opacity(0.75)
        }
        return habit.accentColor
    }

    private var streakColor: Color {
        theme.current == .pride
            ? theme.prideColor(at: habit.currentStreak)
            : habit.accentColor
    }

    private func rateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.7...: return .green
        case 0.4...: return .orange
        default:     return .red
        }
    }

    private var completionRate: Double {
        let cal = Calendar.current
        let past = days.filter { !($0 > cal.startOfDay(for: Date())) }
        guard !past.isEmpty else { return 0 }
        let done = past.filter { habit.isCompleted(on: $0) }.count
        return min(Double(done) / Double(past.count), 1.0)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
