//
//  HabitRowView.swift
//  HabitTracker
//
//  Created by JaceyNguyen on 20/04/2026.
//

import SwiftUI
import SwiftData
import WidgetKit

@MainActor
struct HabitRowView: View {
    @Bindable var habit: Habit
    var onEdit: (() -> Void)? = nil
    var onMilestoneUnlocked: (([MilestoneUnlock]) -> Void)? = nil
    
    @Environment(\.modelContext) private var context
    @State private var bouncing = false
    @State private var showingDecoration = false
    @State private var showingFocus = false
    
    private var decoration: String? {
        let d = habit.decoration(for: Date())
        return d?.isEmpty == false ? d : nil
    }
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            avatarColumn
            infoColumn
            Spacer(minLength: 0)
            trailingColumn
        }
        .padding(.vertical, DSSpacing.sm + 2)
        .padding(.horizontal, DSSpacing.md)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(rowBorder)
        .scaleEffect(bouncing ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: bouncing)
        .onTapGesture { handleTap() }
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $showingDecoration) {
            DecorationPickerView(date: Date(), habit: habit)
        }
        .fullScreenCover(isPresented: $showingFocus) {
            FocusTimerView(habit: habit)
        }
    }
    
    // MARK: - Avatar
    
    private var avatarColumn: some View {
        ZStack(alignment: .bottomTrailing) {
            DSHabitAvatar(
                emoji: habit.emoji,
                color: habit.isCompletedToday
                    ? ThemeManager.shared.accentColor
                    : habit.accentColor,
                size: 48,
                completed: habit.isCompletedToday
            )

            if habit.isCompletedToday, let deco = decoration {
                UniversalSticker(value: deco, fontSize: 16, outlineWidth: 1.5)
                    .offset(x: 6, y: 6)
            }
        }
    }
    
    // MARK: - Info column
    
    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name row
            HStack(spacing: DSSpacing.sm) {
                Text(habit.name)
                    .font(DSFont.bodyBold())
                    .foregroundStyle(
                        habit.isCompletedToday
                        ? Color.dsLabel : Color.dsPrimaryText
                    )
                    .strikethrough(habit.isCompletedToday, color: Color.dsLabel)
                    .lineLimit(1)
                
                if habit.currentStreak > 1 {
                    DSStreakBadge(streak: habit.currentStreak)
                }
            }
            
            // Subtitle
            if !habit.habitDescription.isEmpty {
                Text(habit.habitDescription)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
                    .lineLimit(1)
            }
            
            // Goal progress
            if habit.goal != nil {
                GoalProgressRow(habit: habit)
            }
            
            // Tags
            if !habit.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(habit.tags.prefix(2)) { tag in
                        DSPill(text: tag.label, color: tag.color)
                    }
                    if habit.tags.count > 2 {
                        Text("+\(habit.tags.count - 2)")
                            .font(DSFont.caption(10))
                            .foregroundStyle(Color.dsLabel)
                    }
                }
            }
        }
    }
    
    // MARK: - Trailing column
    
    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: DSSpacing.sm) {
            DSPill(
                text: habit.frequencyLabel,
                color: Color.dsIndigo
            )
            
            if habit.hasFocusTimer {
                Button {
                    showingFocus = true
                } label: {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .semibold))
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
    
    // MARK: - Background + border
    
    private var rowBackground: some View {
        Group {
            if habit.isCompletedToday {
                ThemeManager.shared.accentColor.opacity(0.04)
            } else {
                Color.dsBackground
            }
        }
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: DSRadius.md)
            .strokeBorder(
                habit.isCompletedToday
                    ? ThemeManager.shared.accentColor.opacity(0.25)
                    : Color.dsBorder,
                lineWidth: 1
            )
    }
    
    // MARK: - Context menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button { onEdit?() } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) {
            Task { NotificationManager.shared.cancel(for: habit) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Tap handler
    
    private func handleTap() {
        let wasCompleted = habit.isCompletedToday

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bouncing = true
        }

        // Use mainContext directly to avoid context mismatch
        let mainContext = SharedStore.container.mainContext

        if let goal = habit.goal, goal.type == .nTimes {
            if wasCompleted {
                // Remove one completion from today
                if let idx = habit.completedDates.lastIndex(where: {
                    Calendar.current.isDateInToday($0)
                }) {
                    habit.completedDates.remove(at: idx)
                }
            } else {
                habit.completedDates.append(Date())
                if habit.progressTowardGoal() >= 1.0 {
                    showingDecoration = true
                }
            }
        } else {
            habit.toggleToday()
            if !wasCompleted {
                showingDecoration = true
            }
        }

        WidgetCenter.shared.reloadAllTimelines()

        checkMilestones(context: mainContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            bouncing = false
        }
    }
    
    func checkMilestones(context: ModelContext) -> [MilestoneUnlock] {
        let unlocks = MilestoneEngine.shared.check(habit: habit, context: context)
        for unlock in unlocks {
            NotificationManager.shared.scheduleMilestoneNotification(unlock: unlock)
        }
        return unlocks
    }
}
