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

    // Active focus session for this habit
    private var activeFocusSession: FocusSession? {
        let habitID = habit.id
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate {
                $0.habitID == habitID && !$0.isCompleted
            }
        )
        return try? SharedStore.container.mainContext
            .fetch(descriptor).first
    }

    // Focus progress 0.0–1.0
    private var focusProgress: Double {
        guard let session = activeFocusSession,
              session.durationSeconds > 0 else { return 0 }
        return min(
            Double(session.elapsedSeconds) / Double(session.durationSeconds),
            1.0
        )
    }

    private var decoration: String? {
        let d = habit.decoration(for: Date())
        return d?.isEmpty == false ? d : nil
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Background layer
            backgroundLayer

            // Content
            HStack(spacing: 0) {
                accentStripe
                HStack(spacing: DSSpacing.md) {
                    avatarColumn
                    infoColumn
                    Spacer(minLength: 0)
                    trailingColumn
                }
                .padding(.vertical, DSSpacing.md)
                .padding(.trailing, DSSpacing.md)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(rowBorder)
        .fixedSize(horizontal: false, vertical: true)  // ← auto height
        .scaleEffect(bouncing ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6),
                   value: bouncing)
        .onTapGesture { handleTap() }
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $showingDecoration) {
            DecorationPickerView(date: Date(), habit: habit)
        }
        .fullScreenCover(isPresented: $showingFocus) {
            FocusTimerView(
                habit: habit,
                existingSession: activeFocusSession
            )
        }
    }

    // MARK: - Background layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if habit.isCompletedToday {
            RoundedRectangle(cornerRadius: DSRadius.md)
                .fill(habit.accentColor.opacity(0.12))
        } else if focusProgress > 0 {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DSRadius.md)
                        .fill(Color.dsBackground)
                    RoundedRectangle(cornerRadius: DSRadius.md)
                        .fill(habit.accentColor.opacity(0.15))
                        .frame(width: geo.size.width * focusProgress)
                        .animation(.linear(duration: 1), value: focusProgress)
                }
            }
        } else {
            RoundedRectangle(cornerRadius: DSRadius.md)
                .fill(Color.dsBackground)
        }
    }

    // MARK: - Accent stripe

    private var accentStripe: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(habit.isCompletedToday
                  ? habit.accentColor
                  : habit.accentColor.opacity(0.5))
            .frame(width: 4)
            .padding(.vertical, DSSpacing.sm)
            .padding(.leading, DSSpacing.sm)
    }

    // MARK: - Avatar

    private var avatarColumn: some View {
        ZStack(alignment: .bottomTrailing) {
            DSHabitAvatar(
                emoji: habit.emoji,
                color: habit.isCompletedToday
                    ? habit.accentColor
                    : habit.accentColor.opacity(0.7),
                size: 44,
                completed: habit.isCompletedToday
            )

            if habit.isCompletedToday, let deco = decoration {
                UniversalSticker(value: deco, fontSize: 16, outlineWidth: 1.5)
                    .offset(x: 6, y: 6)
            } else if focusProgress > 0 {
                // Show focus progress ring overlay
                ZStack {
                    Circle()
                        .stroke(Color.dsBorder, lineWidth: 2.5)
                        .frame(width: 18, height: 18)
                    Circle()
                        .trim(from: 0, to: focusProgress)
                        .stroke(
                            habit.accentColor,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 18, height: 18)
                        .animation(.linear(duration: 1), value: focusProgress)
                }
                .background(Color.dsBackground, in: Circle())
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
                            ? habit.accentColor
                            : Color.dsPrimaryText
                    )
                    .strikethrough(habit.isCompletedToday,
                                   color: habit.accentColor.opacity(0.6))
                    .lineLimit(1)                    // ← max 1 line
                    .truncationMode(.tail)           // ← truncate with ...

                if habit.currentStreak > 1 {
                    DSStreakBadge(streak: habit.currentStreak)
                }
            }

            // Subtitle
            if focusProgress > 0, let session = activeFocusSession {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                    Text("\(session.elapsedSeconds / 60)m / \(session.durationSeconds / 60)m · \(Int(focusProgress * 100))%")
                        .font(DSFont.caption())
                }
                .foregroundStyle(habit.accentColor)
            } else if !habit.habitDescription.isEmpty {
                Text(habit.habitDescription)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
                    .lineLimit(1)                    // ← max 1 line
                    .truncationMode(.tail)
            }

            // Goal
            if habit.goal != nil {
                GoalProgressRow(habit: habit)
            }

            // Tags — max 2 + overflow
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
        .frame(maxWidth: .infinity, alignment: .leading)  // ← fill but don't overflow
    }
    
    // MARK: - Trailing column

    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: DSSpacing.sm) {
            DSPill(text: habit.frequencyLabel, color: Color.dsIndigo)

            if habit.hasFocusTimer {
                Image(systemName: focusProgress > 0 ? "timer" : "play.circle.fill")
                    .font(.system(size: focusProgress > 0 ? 12 : 18,
                                  weight: .semibold))
                    .foregroundStyle(habit.accentColor)
                    .padding(focusProgress > 0 ? 6 : 0)
                    .background(
                        focusProgress > 0
                            ? habit.accentColor.opacity(0.1)
                            : Color.clear,
                        in: Circle()
                    )
            }
        }
    }

    // MARK: - Border

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: DSRadius.md)
            .strokeBorder(
                habit.isCompletedToday
                    ? habit.accentColor.opacity(0.3)
                    : focusProgress > 0
                        ? habit.accentColor.opacity(0.4)
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bouncing = true
        }

        if habit.isCompletedToday {
            // Already done — do nothing on tap
            // User must swipe right to undo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bouncing = false
            }
            return
        }

        if habit.hasFocusTimer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showingFocus = true
            }
        } else if let goal = habit.goal, goal.type == .nTimes {
            habit.completedDates.append(Date())
            if habit.progressTowardGoal() >= 1.0 {
                showingDecoration = true
            }
        } else {
            habit.toggleToday()
            showingDecoration = true
        }

        WidgetCenter.shared.reloadAllTimelines()
        checkMilestones(context: SharedStore.container.mainContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            bouncing = false
        }
    }
    
    @MainActor
    func checkMilestones(context: ModelContext) -> Void {
        let unlocks = MilestoneEngine.shared.check(
            habit: habit, context: context
        )
        if !unlocks.isEmpty {
            onMilestoneUnlocked?(unlocks)
            for unlock in unlocks {
                NotificationManager.shared.scheduleMilestoneNotification(
                    unlock: unlock
                )
            }
        }
    }
}
