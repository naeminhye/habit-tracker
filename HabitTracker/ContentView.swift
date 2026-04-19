//
//  ContentView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Filter State

enum HabitFilter: Equatable {
    case all
    case pending
    case completed
    case tag(Tag)

    var label: String {
        switch self {
        case .all:       return "All"
        case .pending:   return "Pending"
        case .completed: return "Done"
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

    var filteredHabits: [Habit] {
        habits.filter { habit in
            let matchesSearch = searchText.isEmpty
                || habit.name.localizedCaseInsensitiveContains(searchText)
                || habit.habitDescription.localizedCaseInsensitiveContains(searchText)
                || habit.tags.contains { $0.label.localizedCaseInsensitiveContains(searchText) }

            let matchesFilter: Bool
            switch activeFilter {
            case .all:         matchesFilter = true
            case .pending:     matchesFilter = !habit.isCompletedToday
            case .completed:   matchesFilter = habit.isCompletedToday
            case .tag(let t):  matchesFilter = habit.tags.contains { $0.id == t.id }
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationTitle("Today")
            .searchable(text: $searchText, prompt: "Search habits…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
    }

    // MARK: - Habit List

    private var habitList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Progress header
                progressHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Filter bar
                filterBar
                    .padding(.horizontal)

                // Empty filtered state
                if filteredHabits.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No habits match")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(filteredHabits) { habit in
                        HabitRow(habit: habit)
                            .padding(.horizontal)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let habit = filteredHabits[index]
                            Task {
                                await NotificationManager.shared.cancel(for: habit)
                                context.delete(habit)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(.all)
                filterChip(.pending)
                filterChip(.completed)
                ForEach(allTags) { tag in
                    filterChip(.tag(tag))
                }
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
                    Circle()
                        .fill(t.color)
                        .frame(width: 6, height: 6)
                }
                Text(filter.label)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isActive ? Color.accentColor : Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .foregroundStyle(isActive ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        let completed = habits.filter(\.isCompletedToday).count
        let total = habits.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0.0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completed) of \(total) done")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline.bold())
            }
            ProgressView(value: progress)
                .tint(completed == total && total > 0 ? .green : .accentColor)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 64))
            Text("No habits yet")
                .font(.title2.bold())
            Text("Tap + to add your first habit")
                .foregroundStyle(.secondary)
            Button("Add a habit") {
                showingAddHabit = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }
}

// MARK: - HabitRow

struct HabitRow: View {
    @Bindable var habit: Habit
    @State private var bouncing = false
    @State private var showingEdit = false
    @State private var showingDecoration = false

    var body: some View {
        HStack(spacing: 16) {
            // Completion ring + emoji
            ZStack {
                Circle()
                    .stroke(
                        habit.isCompletedToday
                            ? habit.accentColor
                            : Color.secondary.opacity(0.3),
                        lineWidth: 2.5
                    )
                    .frame(width: 48, height: 48)
                if habit.isCompletedToday {
                    Circle()
                        .fill(habit.accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                }

                // Habit emoji (main)
                Text(habit.emoji)
                    .font(.title2)
                    .scaleEffect(bouncing ? 1.25 : 1.0)

                // Decoration badge — bottom right, angled
                if habit.isCompletedToday, let deco = habit.decoration(for: Date()) {
                    Text(deco)
                        .font(.system(size: 14))
                        .padding(2)
                        .offset(x: 14, y: 14)
                }
            }

            // Name + description + tags
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.body.bold())
                    .strikethrough(habit.isCompletedToday, color: .secondary)
                    .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)

                if !habit.habitDescription.isEmpty {
                    Text(habit.habitDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if habit.currentStreak > 0 {
                    Label("\(habit.currentStreak) day streak",
                          systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if !habit.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(habit.tags) { tag in
                                TagBadge(tag: tag, small: true)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Frequency badge
            Text(habit.frequencyLabel)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            let wasCompleted = habit.isCompletedToday
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bouncing = true
                habit.toggleToday()
                WidgetCenter.shared.reloadAllTimelines()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bouncing = false
                // Show decoration picker only when marking as done
                if !wasCompleted {
                    showingDecoration = true
                }
            }
        }
        .contextMenu {
            Button {
                showingEdit = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task {
                    NotificationManager.shared.cancel(for: habit)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddHabitView(editingHabit: habit)
        }
        .sheet(isPresented: $showingDecoration) {
            DecorationPickerView(date: Date(), habit: habit)
        }
    }
}

// MARK: - Root Tab View

struct RootView: View {
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
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
