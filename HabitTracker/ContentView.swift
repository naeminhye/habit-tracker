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
    @State private var habitToDelete: Habit? = nil
    @State private var showingDeleteConfirm = false
    @State private var habitToUndone: Habit? = nil
    @State private var showingUndoneConfirm = false
    @State private var completionToasts: [CompletionToast] = []
    
    var dueHabits: [Habit] {
        habits.filter { habit in
            guard habit.isDueToday && !habit.isCompletedToday else { return false }
            return matchesSearch(habit) && matchesFilter(habit)
        }
    }
    
    var completedHabits: [Habit] {
        habits.filter { habit in
            guard habit.isCompletedToday else { return false }
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
    
    var completedCount: Int { habits.filter(\.isCompletedToday).count }
    var totalCount: Int { habits.filter(\.isDueToday).count }
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
                    Color.dsPageBackground.ignoresSafeArea()
                    
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
            // Delete confirm
            .confirmationDialog(
                "Delete \"\(habitToDelete?.name ?? "this habit")\"?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        Task {
                            NotificationManager.shared.cancel(for: habit)
                            if let goal = habit.goal {
                                SharedStore.container.mainContext.delete(goal)
                            }
                            SharedStore.container.mainContext.delete(habit)
                            WidgetCenter.shared.reloadAllTimelines()
                            habitToDelete = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) { habitToDelete = nil }
            } message: {
                Text("This will permanently delete the habit and all its history.")
            }
            // Undo confirm
            .confirmationDialog(
                "Undo \"\(habitToUndone?.name ?? "this habit")\"?",
                isPresented: $showingUndoneConfirm,
                titleVisibility: .visible
            ) {
                Button("Yes, undo it", role: .destructive) {
                    if let habit = habitToUndone {
                        withAnimation {
                            habit.completedDates.removeAll {
                                Calendar.current.isDateInToday($0)
                            }
                            habit.setDecoration(nil, for: Date())
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        habitToUndone = nil
                    }
                }
                Button("Keep it", role: .cancel) { habitToUndone = nil }
            } message: {
                Text("Did you accidentally mark this habit as done?")
            }
            .completionToasts($completionToasts)
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
                    .font(.system(size: 11))
                    .foregroundStyle(Color.htFgSecondary)
                Text("Today")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.htFg)
            }
            .padding(.top, 4)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                // Streak badge
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 12))
                        Text("\(currentStreak)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.htFireFg)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.htFireBg, in: Capsule())
                }
                // User avatar
                ZStack {
                    Circle()
                        .fill(Color.htTintSoft)
                        .frame(width: 28, height: 28)
                    Text(userInitials)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.htTint)
                }
            }
        }
    }
    
    private var currentStreak: Int {
        habits.map(\.currentStreak).max() ?? 0
    }
    
    private var userInitials: String {
        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        if name.isEmpty { return "Me" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    // MARK: - Habit list

    private var habitList: some View {
        List {
            // ── Streak strip (floating, no card) ──
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    // Date sublabel
                    Text(dateSubLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.htFgSecondary)

                    // 7-day strip
                    StreakStripView(habits: habits)

                    // Progress bar
                    VStack(spacing: 4) {
                        HStack {
                            Text("\(completedCount) of \(totalCount) done")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.htFgSecondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.htTint)
                        }
                        DSProgressBar(
                            value: progress,
                            color: Color.htTint,
                            height: 5
                        )
                    }
                }
                .padding(.top, 4)
                .listRowInsets(EdgeInsets(
                    top: 8, leading: DSSpacing.lg,
                    bottom: 8, trailing: DSSpacing.lg
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // ── All-done celebration ──
            if totalCount > 0 && completedCount == totalCount {
                Section {
                    allDoneCard
                        .listRowInsets(EdgeInsets(
                            top: 0, leading: DSSpacing.lg,
                            bottom: 0, trailing: DSSpacing.lg
                        ))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            // ── Search + filter ──
            Section {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        HTFilterChip(
                            label: "All",
                            isActive: activeFilter == .all
                        ) { activeFilter = .all }

                        HTFilterChip(
                            label: "Pending",
                            isActive: activeFilter == .pending
                        ) { activeFilter = .pending }

                        HTFilterChip(
                            label: "Done",
                            isActive: activeFilter == .completed
                        ) { activeFilter = .completed }

                        ForEach(allTags) { tag in
                            HTFilterChip(
                                label: tag.label,
                                isActive: activeFilter == .tag(tag),
                                dotColor: tag.color
                            ) { activeFilter = .tag(tag) }
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // ── Due today ──
            if !dueHabits.isEmpty {
                Section {
                    ForEach(dueHabits) { habit in
                        habitRow(habit)
                    }
                } header: {
                    HTOverline(text: "Due today")
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.top, DSSpacing.sm)
                }
            }

            // ── Completed today ──
            if !completedHabits.isEmpty {
                Section {
                    ForEach(completedHabits) { habit in
                        completedRow(habit)
                    }
                } header: {
                    HTOverline(text: "Completed")
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.top, DSSpacing.sm)
                }
            }

            // ── Upcoming ──
            if !upcomingHabits.isEmpty {
                Section {
                    ForEach(upcomingHabits) { habit in
                        upcomingRow(habit)
                            .listRowInsets(EdgeInsets(
                                top: 4, leading: DSSpacing.lg,
                                bottom: 4, trailing: DSSpacing.lg
                            ))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .opacity(0.6)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                deleteButton(habit)
                                editButton(habit)
                            }
                    }
                } header: {
                    HTOverline(text: "Upcoming")
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.top, DSSpacing.sm)
                }
            }

            // ── Empty state ──
            if dueHabits.isEmpty && completedHabits.isEmpty
                && upcomingHabits.isEmpty {
                Section {
                    emptyFilterState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            // Bottom padding
            Section {
                Color.clear.frame(height: 80)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.htBg)
    }
    
    // MARK: - All-done card

    private var allDoneCard: some View {
        HStack(spacing: 12) {
            Text("🎉").font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text("All done for today!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.htTint)
                Text("100% · Come back tomorrow")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.htTintDeep)
            }
            Spacer()
            Text("100%")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.htTint)
        }
        .padding(DSSpacing.s3)
        .background(Color.htTintSofter,
                    in: RoundedRectangle(cornerRadius: DSRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(Color.htTintSoft, lineWidth: 0.5)
        )
    }

    // MARK: - Date label

    private var dateSubLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date())
    }

    
    // MARK: - Swipe buttons
    
    private func deleteButton(_ habit: Habit) -> some View {
        Button(role: .destructive) {
            habitToDelete = habit
            showingDeleteConfirm = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func editButton(_ habit: Habit) -> some View {
        Button {
            editingHabit = habit
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(Color.dsIndigo)
    }
    
    private func undoButton(_ habit: Habit) -> some View {
        Button {
            habitToUndone = habit
            showingUndoneConfirm = true
        } label: {
            Label("Undo", systemImage: "arrow.uturn.backward")
        }
        .tint(Color.dsGold)
    }
    
    private func completedRow(_ habit: Habit) -> some View {
        HabitRowView(
            habit: habit,
            onEdit: { editingHabit = habit },
            onMilestoneUnlocked: { pendingUnlocks.append(contentsOf: $0) },
            onCompleted: { completionToasts.append($0) }
        )
        .listRowInsets(EdgeInsets(
            top: 4, leading: DSSpacing.lg,
            bottom: 4, trailing: DSSpacing.lg
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            deleteButton(habit)
            editButton(habit)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            undoButton(habit)
        }
    }
    
    // MARK: - Habit row builder

    private func habitRow(_ habit: Habit) -> some View {
        HabitRowView(
            habit: habit,
            onEdit: { editingHabit = habit },
            onMilestoneUnlocked: { pendingUnlocks.append(contentsOf: $0) },
            onCompleted: { completionToasts.append($0) }
        )
        .listRowInsets(EdgeInsets(
            top: 4, leading: DSSpacing.lg,
            bottom: 4, trailing: DSSpacing.lg
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            deleteButton(habit)
            editButton(habit)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            editButton(habit)
        }
    }

    
    // MARK: - Upcoming row

private func upcomingRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(habit.accentColor.opacity(0.4))
                .frame(width: 3, height: 36)

            // Avatar
            ZStack {
                Circle()
                    .fill(habit.accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                Text(habit.emoji)
                    .font(.system(size: 18))
            }
            .opacity(0.6)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.htFgSecondary)
                    .lineLimit(1)
                if let next = habit.nextDueDate {
                    Text("Next: \(next.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.htFgTertiary)
                }
            }

            Spacer()

            Text(habit.frequencyLabel)
                .font(.system(size: 10))
                .foregroundStyle(Color.htFgTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.htSurfaceAlt, in: Capsule())
        }
        .padding(.horizontal, DSSpacing.s3)
        .padding(.vertical, DSSpacing.s2)
        .background(Color.htSurface,
                    in: RoundedRectangle(cornerRadius: DSRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(Color.htBorderC, lineWidth: 0.5)
        )
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
                height: 5
            )
            .animation(.easeOut(duration: 0.2), value: progress)
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
            withAnimation(.easeOut(duration: 0.15)) {   // ← spec: ease-out not spring
                activeFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                if case .tag(let t) = filter {
                    Circle().fill(t.color).frame(width: 5, height: 5)
                }
                Text(filter.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(height: 22)                          // ← spec: 22pt height
            .background(
                isActive ? Color.dsPrimaryText : Color.htPendingBg,
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    isActive ? Color.clear : Color.dsBorder,
                    lineWidth: 0.5
                )
            )
            .foregroundStyle(isActive ? .white : Color.dsLabel)
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

//struct RootView: View {
//    @State private var theme = ThemeManager.shared
//
//    var body: some View {
//        TabView {
//            ContentView()
//                .tabItem {
//                    Label("Today", systemImage: "checkmark.circle.fill")
//                }
//            FocusTabView()
//                .tabItem {
//                    Label("Focus", systemImage: "timer")
//                }
//            HabitProgressView()
//                .tabItem {
//                    Label("Progress", systemImage: "chart.bar.fill")
//                }
//            AchievementsView()
//                .tabItem {
//                    Label("Achievements", systemImage: "medal.fill")
//                }
//            SettingsView()
//                .tabItem {
//                    Label("Settings", systemImage: "gearshape.fill")
//                }
//        }
//        .tint(theme.accentColor)
//    }
//}

struct RootView: View {
    @State private var theme = ThemeManager.shared
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
            HabitProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
            FocusTabView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }
            AchievementsView()
                .tabItem {
                    Label("Awards", systemImage: "medal.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(theme.accentColor)
    }
}
