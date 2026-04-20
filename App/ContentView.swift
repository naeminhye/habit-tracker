//
//  ContentView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Filter

enum HabitFilter: Equatable {
    case all
    case pending
    case completed
    case tag(Tag)
    
    var label: String {
        switch self {
        case .all:        return "All"
        case .pending:    return "Pending"
        case .completed:  return "Done"
        case .tag(let t): return t.label
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Query var habits: [Habit]
    @Query var allTags: [Tag]
    @Environment(\.modelContext) private var context
    @State private var showingAddHabit = false
    @State private var searchText = ""
    @State private var activeFilter: HabitFilter = .all
    @State private var showingStandBy = false
    @State private var editingHabit: Habit? = nil
    @State private var pendingUnlocks: [MilestoneUnlock] = []
    
    var dueHabits: [Habit] {
        habits.filter { habit in
            guard habit.isDueToday else { return false }
            return matchesSearch(habit) && matchesFilter(habit)
        }
    }

    var upcomingHabits: [Habit] {
        habits.filter { habit in
            guard !habit.isDueToday else { return false }
            return matchesSearch(habit) && matchesFilter(habit)
        }
    }

    private func matchesSearch(_ habit: Habit) -> Bool {
        searchText.isEmpty
            || habit.name.localizedCaseInsensitiveContains(searchText)
            || habit.habitDescription.localizedCaseInsensitiveContains(searchText)
            || habit.tags.contains { $0.label.localizedCaseInsensitiveContains(searchText) }
    }

    private func matchesFilter(_ habit: Habit) -> Bool {
        switch activeFilter {
        case .all:        return true
        case .pending:    return !habit.isCompletedToday
        case .completed:  return habit.isCompletedToday
        case .tag(let t): return habit.tags.contains { $0.id == t.id }
        }
    }
    
    var completedCount: Int { dueHabits.filter(\.isCompletedToday).count }
    var totalCount: Int { dueHabits.count }
    var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }
    
    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Main content
                ZStack(alignment: .bottomTrailing) {
                    Color.dsSurface.ignoresSafeArea()

                    if habits.isEmpty {
                        emptyState
                    } else {
                        habitList
                    }

                    // FAB
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                ThemeManager.shared.accentColor,
                                in: Circle()
                            )
                            .shadow(
                                color: ThemeManager.shared.accentColor.opacity(0.4),
                                radius: 12, y: 4
                            )
                    }
                    .padding(.trailing, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.lg)
                }

                // Milestone banner — floats on top of everything
                if let first = pendingUnlocks.first {
                    MilestoneBannerView(unlock: first) {
                        if !pendingUnlocks.isEmpty {
                            pendingUnlocks.removeFirst()
                        }
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7),
                       value: pendingUnlocks.isEmpty)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .searchable(text: $searchText, prompt: "Search habits…")
            .sheet(isPresented: $showingAddHabit) { AddHabitView() }
            .sheet(item: $editingHabit) { habit in
                AddHabitView(editingHabit: habit)
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            VStack(alignment: .leading, spacing: 1) {
                Text(greeting)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
                Text("Today")
                    .font(DSFont.title(20))
                    .foregroundStyle(Color.dsPrimaryText)    // ← was dsIndigo
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(DSFont.caption())
                .foregroundStyle(Color.dsLabel)
        }
    }
    
    // MARK: - Habit list
    
    private var habitList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Streak + progress
                VStack(spacing: DSSpacing.sm) {
                    StreakStripView(habits: habits)
                    progressBar
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.md)
                .padding(.bottom, DSSpacing.lg)

                filterBar
                    .padding(.bottom, DSSpacing.md)

                // Due today
                if dueHabits.isEmpty && upcomingHabits.isEmpty {
                    emptyFilterState
                        .padding(.top, DSSpacing.xxl)
                } else {
                    if !dueHabits.isEmpty {
                        LazyVStack(spacing: DSSpacing.sm) {
                            ForEach(dueHabits) { habit in
                                habitRow(habit)
                            }
                        }
                        .padding(.bottom, DSSpacing.sm)
                    }

                    // Upcoming section
                    if !upcomingHabits.isEmpty {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            DSSectionHeader(
                                title: "Upcoming",
                                count: upcomingHabits.count
                            )
                            .padding(.horizontal, DSSpacing.lg)

                            LazyVStack(spacing: DSSpacing.sm) {
                                ForEach(upcomingHabits) { habit in
                                    upcomingRow(habit)
                                }
                            }
                        }
                        .padding(.top, DSSpacing.sm)
                    }
                }

                Spacer().frame(height: 100)
            }
        }
    }

    // MARK: - Due today row

    private func habitRow(_ habit: Habit) -> some View {
        HabitRowView(
                habit: habit,
                onEdit: { editingHabit = habit },
                onMilestoneUnlocked: { unlocks in
                    pendingUnlocks.append(contentsOf: unlocks)
                }
            )
            .padding(.horizontal, DSSpacing.lg)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    Task {
                        await NotificationManager.shared.cancel(for: habit)
                        context.delete(habit)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { editingHabit = habit } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(Color.dsIndigo)
            }
    }

    // MARK: - Upcoming row (dimmed)

    private func upcomingRow(_ habit: Habit) -> some View {
        HStack(spacing: DSSpacing.md) {
            DSHabitAvatar(
                emoji: habit.emoji,
                color: habit.accentColor,
                size: 40,
                completed: false
            )
            .opacity(0.5)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(DSFont.bodyBold())
                    .foregroundStyle(Color.dsLabel)

                if let next = habit.nextDueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text("Next: \(next.formatted(date: .abbreviated, time: .omitted))")
                            .font(DSFont.caption())
                    }
                    .foregroundStyle(Color.dsLabel)
                }
            }

            Spacer()

            DSPill(text: habit.frequencyLabel, color: Color.dsLabel)
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
        .opacity(0.6)
        .padding(.horizontal, DSSpacing.lg)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await NotificationManager.shared.cancel(for: habit)
                    context.delete(habit)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { editingHabit = habit } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color.dsIndigo)
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(completedCount) of \(totalCount) habits done today")
                    .font(DSFont.body())
                    .foregroundStyle(Color.dsLabel)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(DSFont.bodyBold())
                    .foregroundStyle(ThemeManager.shared.accentColor)
            }
            DSProgressBar(
                value: progress,
                color: ThemeManager.shared.accentColor,
                height: 6
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
    
    // MARK: - Filter bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.sm) {
                Spacer().frame(width: DSSpacing.md)
                filterChip(.all)
                filterChip(.pending)
                filterChip(.completed)
                ForEach(allTags) { tag in
                    filterChip(.tag(tag))
                }
                Spacer().frame(width: DSSpacing.md)
            }
        }
    }
    
    private func filterChip(_ filter: HabitFilter) -> some View {
        let isActive = activeFilter == filter
        return Button {
            withAnimation(.spring(response: 0.3)) {
                activeFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                if case .tag(let t) = filter {
                    Circle().fill(t.color).frame(width: 6, height: 6)
                }
                Text(filter.label)
                    .font(DSFont.bodyBold(13))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isActive ? Color.dsIndigo : Color.dsBackground,
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    isActive ? Color.clear : Color.dsBorder,
                    lineWidth: 1
                )
            )
            .foregroundStyle(isActive ? .white : Color.dsPrimaryText)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty states
    
    private var emptyState: some View {
        VStack(spacing: DSSpacing.lg) {
            Text("🌱")
                .font(.system(size: 64))
            Text("No habits yet")
                .font(DSFont.title())
                .foregroundStyle(Color.dsPrimaryText)
            Text("Tap the + button to add your first habit")
                .font(DSFont.body())
                .foregroundStyle(Color.dsLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DSSpacing.xxl)
    }
    
    private var emptyFilterState: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.dsLabel)
            Text("No habits match")
                .font(DSFont.title())
                .foregroundStyle(Color.dsIndigo)
        }
    }
}

// MARK: - HabitRow

struct HabitRow: View {
    @Bindable var habit: Habit
    var onEdit: (() -> Void)? = nil
    @Environment(\.modelContext) private var context
    @State private var bouncing = false
    @State private var showingEdit = false
    @State private var showingDecoration = false
    @State private var showingFocus = false
    @State private var pendingUnlocks: [MilestoneUnlock] = []
    
    var body: some View {
        HStack(spacing: 0) {
            // Accent stripe
            RoundedRectangle(cornerRadius: 3)
                .fill(habit.isCompletedToday ? ThemeManager.shared.accentColor : habit.accentColor)
                .frame(width: 4)
                .padding(.vertical, DSSpacing.sm)
                .padding(.leading, DSSpacing.sm)
            
            HStack(spacing: DSSpacing.md) {
                // Habit emoji avatar — always rotation 0, no decoration shown here
                DSHabitAvatar(
                    emoji: habit.emoji,
                    color: habit.isCompletedToday
                    ? ThemeManager.shared.accentColor : habit.accentColor,
                    size: 48,
                    completed: habit.isCompletedToday
                )
                
                // Decoration badge — bottom right, angled
                if habit.isCompletedToday,
                   let deco = habit.decoration(for: Date()),
                   !deco.isEmpty {
                    UniversalSticker(value: deco, fontSize: 18, outlineWidth: 2)
                        .offset(x: 8, y: 8)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DSSpacing.sm) {
                        Text(habit.name)
                            .font(DSFont.bodyBold())
                            .foregroundStyle(
                                habit.isCompletedToday
                                ? Color.dsLabel : Color.dsIndigo
                            )
                            .strikethrough(habit.isCompletedToday,
                                           color: Color.dsLabel)
                        
                        if habit.currentStreak > 0 {
                            DSStreakBadge(streak: habit.currentStreak)
                        }
                    }
                    
                    if !habit.habitDescription.isEmpty {
                        Text(habit.habitDescription)
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                            .lineLimit(1)
                    }
                    
                    if !habit.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(habit.tags.prefix(2)) { tag in
                                DSPill(text: tag.label, color: tag.color)
                            }
                        }
                    }
                    
                    if habit.goal != nil {
                        GoalProgressRow(habit: habit)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Right side
                VStack(alignment: .trailing, spacing: 6) {
                    DSPill(
                        text: habit.frequencyLabel,
                        color: Color.dsIndigo
                    )
                    
                    if habit.hasFocusTimer {
                        Button {
                            showingFocus = true
                        } label: {
                            Image(systemName: "timer")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(habit.accentColor)
                                .padding(6)
                                .background(
                                    habit.accentColor.opacity(0.1),
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(DSSpacing.md)
        }
        .background(
            Color.dsBackground,
            in: RoundedRectangle(cornerRadius: DSRadius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(
                    habit.isCompletedToday
                    ? Color.dsMint.opacity(0.3) : Color.dsBorder,
                    lineWidth: 1
                )
        )
        .onTapGesture {
            let wasCompleted = habit.isCompletedToday
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bouncing = true
                if let goal = habit.goal, goal.type == .nTimes {
                    habit.completedDates.append(Date())
                    if habit.progressTowardGoal() >= 1.0 && !wasCompleted {
                        showingDecoration = true
                    }
                } else {
                    habit.toggleToday()
                    if !wasCompleted { showingDecoration = true }
                }
                WidgetCenter.shared.reloadAllTimelines()
                checkMilestones()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bouncing = false
            }
        }
        .contextMenu {
            Button { onEdit?() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task { NotificationManager.shared.cancel(for: habit) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDecoration) {
            DecorationPickerView(date: Date(), habit: habit)
        }
        .fullScreenCover(isPresented: $showingFocus) {
            FocusTimerView(habit: habit)
        }
        .milestoneOverlay(unlocks: $pendingUnlocks)
    }
    
    @MainActor private func checkMilestones() {
        let unlocks = MilestoneEngine.shared.check(
            habit: habit, context: context
        )
        if !unlocks.isEmpty {
            pendingUnlocks.append(contentsOf: unlocks)
            for unlock in unlocks {
                NotificationManager.shared.scheduleMilestoneNotification(
                    unlock: unlock
                )
            }
        }
    }
}

// MARK: - RootView

struct RootView: View {
    @State private var theme = ThemeManager.shared
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
            FocusTabView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
            HabitProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "medal.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(theme.accentColor)
    }
}
