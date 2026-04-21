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
    @State private var showingShareProgress = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsPageBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Custom nav bar
                    navBar
                    // Stats strip
                    statsStrip
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.vertical, DSSpacing.md)
                    DSDivider()
                    // Content
                    if viewMode == .month {
                        MonthCalendarView()
                    } else {
                        habitHeatmapView
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareProgress) {
                ShareProgressView()
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PROGRESS")
                    .font(DSFont.overline())
                    .foregroundStyle(Color.dsLabel)
                    .kerning(1)
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(DSFont.displayM())
                    .foregroundStyle(Color.dsIndigo)
            }

            Spacer()

            HStack(spacing: DSSpacing.sm) {
                // View switcher
                HStack(spacing: 2) {
                    modeButton(mode: .month, icon: "calendar")
                    modeButton(mode: .habits, icon: "chart.bar.fill")
                }
                .padding(3)
                .background(Color.dsBorder, in: Capsule())

                // Share
                Button {
                    showingShareProgress = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dsIndigo)
                        .frame(width: 36, height: 36)
                        .background(Color.dsBackground, in: Circle())
                        .overlay(Circle().strokeBorder(Color.dsBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.top, DSSpacing.md)
        .padding(.bottom, DSSpacing.sm)
    }

    // MARK: - Mode button

    private func modeButton(mode: ProgressViewMode, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { viewMode = mode }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(viewMode == mode ? .white : Color.dsLabel)
                .frame(width: 34, height: 28)
                .background(
                    viewMode == mode ? Color.dsIndigo : Color.clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        let best = habits.map(\.currentStreak).max() ?? 0
        let done = habits.filter(\.isCompletedToday).count
        let total = habits.count
        let totalCheckIns = habits.flatMap(\.completedDates).count

        return HStack(spacing: 0) {
            DSStatBadge(
                value: "\(done)/\(total)",
                label: "TODAY",
                color: .dsAccent
            )
            dsVerticalDivider
            DSStatBadge(
                value: "\(best)",
                label: "BEST STREAK",
                color: .dsGold,
                icon: "flame.fill"
            )
            dsVerticalDivider
            DSStatBadge(
                value: "\(totalCheckIns)",
                label: "ALL TIME",
                color: .dsIndigo
            )
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground, in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
    }

    private var dsVerticalDivider: some View {
        Rectangle()
            .fill(Color.dsBorder)
            .frame(width: 1, height: 36)
    }

    // MARK: - Habit heatmap view

    private var habitHeatmapView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: DSSpacing.md) {
                ForEach(habits) { habit in
                    HabitProgressCard(habit: habit)
                        .padding(.horizontal, DSSpacing.lg)
                }
            }
            .padding(.vertical, DSSpacing.md)
            .padding(.bottom, DSSpacing.xxl)
        }
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
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            headerRow
            weekdayLabels
            heatmapGrid
            DSDivider()
            completionBar
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
        .sheet(item: $decoratingDate) { item in
            DecorationPickerView(date: item.date, habit: habit)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: DSSpacing.sm) {
            DSHabitAvatar(
                emoji: habit.emoji,
                color: habit.accentColor,
                size: 40,
                completed: habit.isCompletedToday
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(DSFont.bodyBold())
                    .foregroundStyle(Color.dsIndigo)
                Text(habit.habitDescription.isEmpty
                     ? habit.frequencyLabel
                     : habit.habitDescription)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                DSStreakBadge(streak: habit.currentStreak, large: true)
                if habit.hasFocusTimer {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text("\(habit.focusDurationMinutes)m")
                            .font(DSFont.caption())
                    }
                    .foregroundStyle(Color.dsLabel)
                }
            }
        }
    }

    // MARK: - Weekday labels

    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                Text(d)
                    .font(DSFont.caption(9))
                    .foregroundStyle(Color.dsLabel)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Heatmap

    private var heatmapGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                           count: columns),
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
            // Cell background
            RoundedRectangle(cornerRadius: 5)
                .fill(cellFill(
                    completed: isCompleted,
                    future: isFuture,
                    index: index
                ))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(
                            isToday ? Color.dsAccent : Color.clear,
                            lineWidth: 1.5
                        )
                )

            if let deco = decoration {
                StickerText(text: deco, fontSize: 9, outlineWidth: 1)
            } else if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .opacity(isFuture ? 0.25 : 1)
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
    }

    // MARK: - Completion bar

    private var completionBar: some View {
        let rate = completionRate
        return HStack(spacing: DSSpacing.sm) {
            DSProgressBar(value: rate, color: habitRateColor(rate), height: 5)
            Text("\(Int(rate * 100))%")
                .font(DSFont.bodyBold(12))
                .foregroundStyle(habitRateColor(rate))
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private func cellFill(completed: Bool, future: Bool, index: Int) -> Color {
        if future { return Color.htHm0 }
        guard completed else { return Color.htHmMiss }
        // Level based on streak/goal
        let progress = habit.progressTowardGoal()
        if progress >= 1.5 { return Color.htHm3 }
        if progress >= 1.0 { return Color.htHm2 }
        return Color.htHm1
    }
    
    private func habitRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.7...: return .dsMint
        case 0.4...: return .dsGold
        default:     return .accentColor
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
