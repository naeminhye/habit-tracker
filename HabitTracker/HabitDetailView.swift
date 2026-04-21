//
//  HabitDetailView.swift
//  HabitTracker
//
//  Created by BangChitty on 21/04/2026.
//

import SwiftUI
import SwiftData

@MainActor
struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query var allSessions: [FocusSession]
    
    @State private var subView: DetailSubView = .overview
    @State private var showingEdit = false
    @State private var showingFocus = false
    
    enum DetailSubView: String, CaseIterable {
        case overview = "Overview"
        case history  = "History"
        case focus    = "Focus"
    }
    
    private var sessions: [FocusSession] {
        allSessions.filter { $0.habitID == habit.id }
    }
    
    private var todaySession: FocusSession? {
        sessions.first {
            Calendar.current.isDateInToday($0.startedAt) && !$0.isCompleted
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsPageBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    subViewPicker
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.vertical, DSSpacing.md)
                    DSDivider()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DSSpacing.lg) {
                            switch subView {
                            case .overview: overviewContent
                            case .history:  historyContent
                            case .focus:    focusContent
                            }
                        }
                        .padding(DSSpacing.lg)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.dsLabel)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEdit = true
                    } label: {
                        Text("Edit")
                            .font(DSFont.bodyBold())
                            .foregroundStyle(ThemeManager.shared.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddHabitView(editingHabit: habit)
            }
            .fullScreenCover(isPresented: $showingFocus) {
                FocusTimerView(
                    habit: habit,
                    existingSession: todaySession
                )
            }
        }
    }
    
    // MARK: - Sub view picker
    
    private var subViewPicker: some View {
        HStack(spacing: 4) {
            ForEach(DetailSubView.allCases, id: \.self) { sv in
                let isActive = subView == sv
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        subView = sv
                    }
                } label: {
                    Text(sv.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isActive ? Color.dsPrimaryText : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(isActive ? .white : Color.dsLabel)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    // MARK: - Overview
    
    private var overviewContent: some View {
        VStack(spacing: DSSpacing.lg) {
            streakHeroCard
            statTiles
            if habit.goal != nil { goalCard }
            if let next = nextMilestone { nextMilestoneCard(next) }
            ctaRow
        }
    }
    
    // Streak hero card
    private var streakHeroCard: some View {
        HStack(spacing: DSSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(habit.currentStreak)")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(ThemeManager.shared.accentColor)
                Text("day streak")
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(Color.dsBorder)
                .frame(width: 0.5, height: 44)
            
            // 7-day strip
            StreakStripView(habits: [habit])
                .frame(maxWidth: .infinity)
        }
        .padding(DSSpacing.md)
        .background(
            ThemeManager.shared.accentColor.opacity(0.06),
            in: RoundedRectangle(cornerRadius: DSRadius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(ThemeManager.shared.accentColor.opacity(0.15),
                              lineWidth: 0.5)
        )
    }
    
    // 2×2 stat tiles
    private var statTiles: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(),
                           spacing: DSSpacing.sm), count: 2),
            spacing: DSSpacing.sm
        ) {
            statTile("Completion",
                     value: "\(completionRatePercent)%",
                     color: ThemeManager.shared.accentColor)
            statTile("Best streak",
                     value: "\(bestStreak)",
                     color: Color.dsGold)
            statTile("Total done",
                     value: "\(habit.totalCompletions)",
                     color: Color.dsPrimaryText)
            statTile("Avg / week",
                     value: avgPerWeek,
                     color: Color.dsLabel)
        }
    }

    private func statTile(_ label: String,
                          value: String,
                          color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DSFont.overline())
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)
            Text(value)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    // Goal card
    private var goalCard: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("TODAY'S GOAL")
                .font(DSFont.overline())
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.goal?.displayTarget ?? "")
                        .font(DSFont.bodyBold())
                        .foregroundStyle(Color.dsPrimaryText)
                    Text(habit.goalProgressLabel)
                        .font(DSFont.caption())
                        .foregroundStyle(ThemeManager.shared.accentColor)
                }
                Spacer()
                Text("\(Int(habit.progressTowardGoal() * 100))%")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ThemeManager.shared.accentColor)
            }
            
            DSProgressBar(
                value: habit.progressTowardGoal(),
                color: ThemeManager.shared.accentColor
            )
        }
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    // Next milestone card
    private func nextMilestoneCard(_ milestone: Milestone) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("NEXT MILESTONE")
                    .font(DSFont.overline())
                    .foregroundStyle(Color.dsLabel)
                    .kerning(0.5)
                HStack(spacing: 6) {
                    Text(milestone.emoji)
                    Text(milestone.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dsPrimaryText)
                }
                Text(milestone.progressDescription)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
            }
            Spacer()
            // Countdown badge
            ZStack {
                Circle()
                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
                    .frame(width: 40, height: 40)
                Text("\(max(0, milestone.targetValue - habit.totalCompletions))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeManager.shared.accentColor)
            }
        }
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    // CTA row
    private var ctaRow: some View {
        HStack(spacing: DSSpacing.sm) {
            if habit.hasFocusTimer {
                DSButton(
                    title: "Start timer",
                    icon: "timer",
                    color: ThemeManager.shared.accentColor,
                    style: .secondary
                ) {
                    showingFocus = true
                }
            }
            DSButton(
                title: habit.isCompletedToday
                ? "Completed ✓" : "Mark complete",
                color: ThemeManager.shared.accentColor,
                style: .primary
            ) {
                if !habit.isCompletedToday {
                    habit.toggleToday()
                }
            }
            .disabled(habit.isCompletedToday)
            .opacity(habit.isCompletedToday ? 0.6 : 1)
        }
    }
    
    // MARK: - History
    
    private var historyContent: some View {
        VStack(spacing: DSSpacing.lg) {
            // Heatmap
            heatmapSection
            
            // Completion bars
            completionBarsSection
            
            // Calendar month
            MonthCalendarView()
                .frame(height: 340)
                .background(Color.dsCardBackground,
                            in: RoundedRectangle(cornerRadius: DSRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.md)
                        .strokeBorder(Color.dsBorder, lineWidth: 0.5)
                )
        }
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("5-WEEK HEATMAP")
                .font(DSFont.overline())
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)
            
            HabitProgressCard(habit: habit)
        }
    }
    
    private var completionBarsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("COMPLETION RATE")
                .font(DSFont.overline())
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)
            
            VStack(spacing: DSSpacing.sm) {
                completionBar(
                    label: "This week",
                    value: weeklyCompletionRate
                )
                completionBar(
                    label: "This month",
                    value: monthlyCompletionRate
                )
                completionBar(
                    label: "All time",
                    value: allTimeCompletionRate
                )
            }
            .padding(DSSpacing.md)
            .background(Color.dsCardBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
            )
        }
    }
    
    private func completionBar(label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsLabel)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(rateColor(value))
            }
            DSProgressBar(value: value, color: rateColor(value), height: 5)
        }
    }
    
    private func rateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.8...: return ThemeManager.shared.accentColor
        case 0.4...: return Color(hex: "BA7517")
        default:     return Color(hex: "A32D2D")
        }
    }
    
    // MARK: - Focus
    
    private var focusContent: some View {
        VStack(spacing: DSSpacing.lg) {
            // Focus stats
            focusStatsCard
            
            // Duration presets reminder
            if habit.hasFocusTimer {
                currentTimerCard
            }
            
            // Session history
            if sessions.isEmpty {
                emptyFocusState
            } else {
                focusSessionList
            }
        }
    }
    
    private var focusStatsCard: some View {
        let completedSessions = sessions.filter(\.isCompleted)
        let totalMinutes = completedSessions.reduce(0) {
            $0 + $1.durationSeconds
        } / 60
        let avgMinutes = completedSessions.isEmpty
        ? 0 : totalMinutes / completedSessions.count
        
        let stats: [(String, String)] = [
            ("Sessions", "\(completedSessions.count)"),
            ("Total time", formatMinutes(totalMinutes)),
            ("Avg session", formatMinutes(avgMinutes)),
        ]
        
        return HStack(spacing: 0) {
            ForEach(stats.indices, id: \.self) { i in
                VStack(spacing: 4) {
                    Text(stats[i].1)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(ThemeManager.shared.accentColor)
                    Text(stats[i].0)
                        .font(DSFont.overline())
                        .foregroundStyle(Color.dsLabel)
                        .kerning(0.5)
                }
                .frame(maxWidth: .infinity)
                
                if i < stats.count - 1 {
                    Rectangle()
                        .fill(Color.dsBorder)
                        .frame(width: 0.5, height: 32)
                }
            }
        }
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    private var currentTimerCard: some View {
        HStack(spacing: DSSpacing.md) {
            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color.dsBorder, lineWidth: 3)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0,
                          to: todaySession.map { Double($0.elapsedSeconds) /
                        Double($0.durationSeconds) } ?? 0)
                    .stroke(ThemeManager.shared.accentColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.linear(duration: 1),
                               value: todaySession?.elapsedSeconds)
                VStack(spacing: 1) {
                    Text(todaySession?.formattedRemaining
                         ?? formatMinutes(habit.focusDurationMinutes))
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    Text("focus")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.dsLabel)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(todaySession != nil ? "Session paused" : "Ready to focus")
                    .font(DSFont.bodyBold())
                    .foregroundStyle(Color.dsPrimaryText)
                Text("\(habit.focusDurationMinutes) min · \(habit.deepFocusEnabled ? "Deep focus" : "Standard")")
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
            }
            
            Spacer()
            
            Button {
                showingFocus = true
            } label: {
                Text(todaySession != nil ? "Resume" : "Start")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ThemeManager.shared.accentColor,
                                in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    private var emptyFocusState: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "timer")
                .font(.system(size: 32))
                .foregroundStyle(Color.dsBorder)
            Text("No focus sessions yet")
                .font(DSFont.body())
                .foregroundStyle(Color.dsLabel)
            if habit.hasFocusTimer {
                DSButton(
                    title: "Start first session",
                    icon: "play.fill",
                    color: ThemeManager.shared.accentColor
                ) {
                    showingFocus = true
                }
                .padding(.horizontal, DSSpacing.xxl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DSSpacing.xxl)
    }
    
    private var focusSessionList: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("SESSION HISTORY")
                .font(DSFont.overline())
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)

            VStack(spacing: DSSpacing.sm) {
                ForEach(Array(sessions.prefix(20))) { session in
                    focusSessionRow(session)
                }
            }
        }
    }
    
    private func focusSessionRow(_ session: FocusSession) -> some View {
        HStack(spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.startedAt.formatted(
                    date: .abbreviated, time: .shortened
                ))
                .font(.system(size: 11))
                .foregroundStyle(Color.dsPrimaryText)
                
                if !session.isCompleted && session.elapsedSeconds > 0 {
                    Text("\(session.elapsedSeconds / 60)m elapsed · Paused")
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsGold)
                }
            }
            
            Spacer()
            
            // Duration chip
            Text(session.formattedDuration)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(
                    session.isCompleted
                    ? ThemeManager.shared.accentColor
                    : Color.dsLabel
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    session.isCompleted
                    ? ThemeManager.shared.accentColor.opacity(0.1)
                    : Color.dsCardBackground,
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        session.isCompleted
                        ? ThemeManager.shared.accentColor.opacity(0.3)
                        : Color.dsBorder,
                        lineWidth: 0.5
                    )
                )
        }
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    // MARK: - Helpers
    
    @Query private var allMilestones: [Milestone]

    private var nextMilestone: Milestone? {
        allMilestones
            .filter {
                !$0.isReached &&
                ($0.habitID == nil || $0.habitID == habit.id)
            }
            .sorted { $0.targetValue < $1.targetValue }
            .first
    }
    
    private var bestStreak: Int {
        var best = 0
        var current = 0
        let cal = Calendar.current
        let sorted = habit.completedDates
            .map { cal.startOfDay(for: $0) }
            .sorted()
        var prev: Date? = nil
        for date in sorted {
            if let p = prev,
               cal.dateComponents([.day], from: p, to: date).day == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            prev = date
        }
        return best
    }
    
    private var completionRatePercent: Int {
        guard !habit.completedDates.isEmpty else { return 0 }
        let cal = Calendar.current
        let start = cal.startOfDay(for: habit.startDate)
        let today = cal.startOfDay(for: Date())
        let days = cal.dateComponents([.day], from: start, to: today).day ?? 1
        guard days > 0 else { return 100 }
        return min(100, Int(Double(habit.totalCompletions) / Double(days) * 100))
    }
    
    private var avgPerWeek: String {
        let cal = Calendar.current
        let weeks = max(1, (cal.dateComponents(
            [.weekOfYear],
            from: habit.startDate,
            to: Date()
        ).weekOfYear ?? 1))
        let avg = Double(habit.totalCompletions) / Double(weeks)
        return String(format: "%.1f", avg)
    }
    
    private var weeklyCompletionRate: Double {
        let cal = Calendar.current
        let days = (0..<7).compactMap {
            cal.date(byAdding: .day, value: -$0, to: Date())
        }
        let done = days.filter { habit.isCompleted(on: $0) }.count
        return Double(done) / 7.0
    }
    
    private var monthlyCompletionRate: Double {
        let cal = Calendar.current
        let days = (0..<30).compactMap {
            cal.date(byAdding: .day, value: -$0, to: Date())
        }
        let done = days.filter { habit.isCompleted(on: $0) }.count
        return Double(done) / 30.0
    }
    
    private var allTimeCompletionRate: Double {
        let cal = Calendar.current
        let daysSince = max(1, cal.dateComponents(
            [.day],
            from: habit.startDate,
            to: Date()
        ).day ?? 1)
        return min(1.0, Double(habit.totalCompletions) / Double(daysSince))
    }
    
    private func formatMinutes(_ min: Int) -> String {
        if min < 60 { return "\(min)m" }
        let h = min / 60
        let m = min % 60
        return m > 0 ? "\(h)h\(m)m" : "\(h)h"
    }
}
