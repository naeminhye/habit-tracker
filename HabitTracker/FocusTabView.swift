//
//  FocusTabView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

struct FocusTabView: View {
    @Query(sort: \FocusSession.startedAt, order: .reverse) var sessions: [FocusSession]
    @Query var habits: [Habit]
    @State private var selectedHabit: Habit? = nil

    var todaySessions: [FocusSession] {
        sessions.filter {
            Calendar.current.isDateInToday($0.startedAt)
        }
    }

    var todayFocusMinutes: Int {
        todaySessions.filter(\.isCompleted)
            .reduce(0) { $0 + $1.durationSeconds } / 60
    }

    var totalFocusMinutes: Int {
        sessions.filter(\.isCompleted)
            .reduce(0) { $0 + $1.durationSeconds } / 60
    }

    var focusHabits: [Habit] { habits.filter(\.hasFocusTimer) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsPageBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DSSpacing.lg) {
                            statsCard
                                .padding(.horizontal, DSSpacing.lg)
                            if !focusHabits.isEmpty {
                                quickStartSection
                                    .padding(.horizontal, DSSpacing.lg)
                            }
                            todaySection
                                .padding(.horizontal, DSSpacing.lg)
                            if sessions.contains(where: {
                                !Calendar.current.isDateInToday($0.startedAt)
                            }) {
                                recentSection
                                    .padding(.horizontal, DSSpacing.lg)
                            }
                        }
                        .padding(.top, DSSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedHabit) { habit in
                FocusTimerView(habit: habit)
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FOCUS")
                    .font(DSFont.overline())
                    .foregroundStyle(Color.dsLabel)
                    .kerning(1)
                Text("\(todayFocusMinutes) min today")
                    .font(DSFont.displayM())
                    .foregroundStyle(Color.dsIndigo)
            }
            Spacer()
            // Today's session count badge
            if !todaySessions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(todaySessions.filter(\.isCompleted).count) done")
                        .font(DSFont.bodyBold(12))
                }
                .foregroundStyle(Color.dsAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.dsAccent.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.top, DSSpacing.md)
        .padding(.bottom, DSSpacing.sm)
    }

    // MARK: - Stats card

    private var statsCard: some View {
        HStack(spacing: 0) {
            DSStatBadge(
                value: "\(todayFocusMinutes)m",
                label: "TODAY",
                color: .accentColor,
                icon: "timer"
            )
            dsVerticalDivider
            DSStatBadge(
                value: "\(todaySessions.filter(\.isCompleted).count)",
                label: "SESSIONS",
                color: .dsIndigo
            )
            dsVerticalDivider
            DSStatBadge(
                value: formatTotal(totalFocusMinutes),
                label: "ALL TIME",
                color: .dsGold
            )
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
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

    // MARK: - Quick start

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Start a session", count: focusHabits.count)

            ForEach(focusHabits) { habit in
                DSFocusHabitCard(habit: habit) {
                    selectedHabit = habit
                }
            }
        }
    }

    // MARK: - Today's sessions

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Today", count: todaySessions.count)

            if todaySessions.isEmpty {
                emptySessionsCard
            } else {
                VStack(spacing: DSSpacing.sm) {
                    ForEach(todaySessions) { session in
                        DSSessionRow(session: session)
                    }
                }
            }
        }
    }

    // MARK: - Recent sessions

    private var recentSection: some View {
        let older = sessions.filter {
            !Calendar.current.isDateInToday($0.startedAt)
        }
        let recent = Array(older.prefix(8))

        return VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Recent", count: older.count)
            VStack(spacing: DSSpacing.sm) {
                ForEach(recent) { session in
                    DSSessionRow(session: session)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptySessionsCard: some View {
        HStack {
            Spacer()
            VStack(spacing: DSSpacing.sm) {
                Image(systemName: "timer")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.dsBorder)
                Text("No sessions yet today")
                    .font(DSFont.body())
                    .foregroundStyle(Color.dsLabel)
                if !focusHabits.isEmpty {
                    Text("Tap a habit above to start")
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel.opacity(0.6))
                }
            }
            .padding(DSSpacing.xl)
            Spacer()
        }
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
    }

    private func formatTotal(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m > 0 ? "\(h)h\(m)m" : "\(h)h"
    }
}

// MARK: - DSFocusHabitCard

struct DSFocusHabitCard: View {
    let habit: Habit
    let onStart: () -> Void
    @State private var pressing = false

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Left stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(habit.accentColor)
                .frame(width: 4)
                .padding(.vertical, DSSpacing.sm)

            DSHabitAvatar(
                emoji: habit.emoji,
                color: habit.accentColor,
                size: 44,
                completed: habit.isCompletedToday
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(DSFont.bodyBold())
                    .foregroundStyle(Color.dsIndigo)

                HStack(spacing: DSSpacing.sm) {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text("\(habit.focusDurationMinutes) min")
                            .font(DSFont.caption())
                    }
                    .foregroundStyle(Color.dsLabel)

                    if habit.currentStreak > 0 {
                        DSStreakBadge(streak: habit.currentStreak)
                    }

                    if habit.deepFocusEnabled {
                        DSPill(text: "deep", color: .dsIndigo)
                    }
                }
            }

            Spacer()

            // Play button
            Button(action: onStart) {
                ZStack {
                    Circle()
                        .fill(habit.accentColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 1.5)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(pressing ? 0.92 : 1.0)
            .animation(.spring(response: 0.2), value: pressing)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressing = true }
                    .onEnded { _ in pressing = false }
            )
        }
        .padding(.vertical, DSSpacing.sm)
        .padding(.trailing, DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
    }
}

// MARK: - DSSessionRow

struct DSSessionRow: View {
    let session: FocusSession

    private var statusColor: Color {
        if session.isCompleted { return Color.dsMint }
        if session.elapsedSeconds > 0 { return Color.dsGold }
        return Color.dsBorder
    }

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Emoji circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Circle()
                    .strokeBorder(statusColor, lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                Text(session.habitEmoji)
                    .font(.system(size: 20))
                    .opacity(session.isCompleted ? 1 : 0.6)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(session.habitName)
                    .font(DSFont.bodyBold())
                    .foregroundStyle(
                        session.isCompleted ? Color.dsIndigo : Color.dsPrimaryText
                    )
                HStack(spacing: DSSpacing.sm) {
                    Text(session.formattedDuration)
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel)
                    Text("·")
                        .foregroundStyle(Color.dsBorder)
                    Text(session.startedAt.formatted(
                        date: .omitted, time: .shortened
                    ))
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)

                    // Show elapsed if paused
                    if !session.isCompleted && session.elapsedSeconds > 0 {
                        Text("· \(session.elapsedSeconds / 60)m elapsed")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsGold)
                    }
                }
            }

            Spacer()

            // Status
            if session.isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dsMint)
                    Text("Done")
                        .font(DSFont.bodyBold(12))
                        .foregroundStyle(Color.dsMint)
                }
            } else if session.elapsedSeconds > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(Color.dsGold)
                    Text("Paused")
                        .font(DSFont.bodyBold(12))
                        .foregroundStyle(Color.dsGold)
                }
            } else {
                Text("Cancelled")
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dsBorder.opacity(0.4), in: Capsule())
            }
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(statusColor.opacity(0.2), lineWidth: 1)
        )
    }
}
