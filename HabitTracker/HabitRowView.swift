//
//  HabitRowView.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI
import SwiftData
import WidgetKit

@MainActor
struct HabitRowView: View {
    @Bindable var habit: Habit
    var onEdit: (() -> Void)? = nil
    var onMilestoneUnlocked: (([MilestoneUnlock]) -> Void)? = nil
    var onCompleted: ((CompletionToast) -> Void)? = nil

    @Environment(\.modelContext) private var context
    @State private var bouncing = false
    @State private var showingDecoration = false
    @State private var showingFocus = false
    @State private var showingDetail = false

    private var decoration: String? {
        let d = habit.decoration(for: Date())
        return d?.isEmpty == false ? d : nil
    }

    private var activeFocusSession: FocusSession? {
        let habitID = habit.id
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.habitID == habitID && !$0.isCompleted }
        )
        return try? SharedStore.container.mainContext.fetch(descriptor).first
    }

    private var focusProgress: Double {
        guard let s = activeFocusSession, s.durationSeconds > 0 else { return 0 }
        return min(Double(s.elapsedSeconds) / Double(s.durationSeconds), 1.0)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Card bg
            RoundedRectangle(cornerRadius: DSRadius.card)
                .fill(habit.isCompletedToday
                      ? habit.accentColor.opacity(0.04)
                      : Color.htSurface)

            // Focus progress split
            if focusProgress > 0 && !habit.isCompletedToday {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: DSRadius.card)
                            .fill(habit.accentColor.opacity(0.08))
                            .frame(width: geo.size.width * focusProgress)
                            .animation(DSAnim.base, value: focusProgress)
                        Spacer(minLength: 0)
                    }
                }
            }

            HStack(spacing: 0) {
                // 3pt accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(habit.accentColor)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 10)
                    .padding(.leading, 10)

                HStack(spacing: 10) {
                    // Avatar
                    avatarView
                    // Content
                    contentColumn
                    Spacer(minLength: 0)
                    // Status chip
                    statusArea
                        .padding(.trailing, 12)
                }
                .padding(.vertical, 12)
                .padding(.leading, 10)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(
                    habit.isCompletedToday
                        ? habit.accentColor.opacity(0.2)
                        : Color.htBorderC,
                    lineWidth: 0.5
                )
        )
        .scaleEffect(bouncing ? 0.97 : 1.0)
        .animation(DSAnim.fast, value: bouncing)
        .onTapGesture { handleTap() }
        .onLongPressGesture(minimumDuration: 0.5) {
            showingDetail = true
        }
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $showingDecoration) {
            DecorationPickerView(date: Date(), habit: habit)
        }
        .fullScreenCover(isPresented: $showingFocus) {
            FocusTimerView(habit: habit, existingSession: activeFocusSession)
        }
        .sheet(isPresented: $showingDetail) {
            HabitDetailView(habit: habit)
        }
    }

    // MARK: - Avatar (40pt per spec)

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(habit.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                // Focus ring
                if focusProgress > 0 {
                    Circle()
                        .trim(from: 0, to: focusProgress)
                        .stroke(habit.accentColor,
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    lineCap: .round
                                ))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 40, height: 40)
                        .animation(DSAnim.base, value: focusProgress)
                }

                Text(habit.emoji)
                    .font(.system(size: 20))
            }

            // Decoration badge
            if habit.isCompletedToday, let deco = decoration {
                UniversalSticker(value: deco, fontSize: 13, outlineWidth: 1.5)
                    .offset(x: 4, y: 4)
            }
        }
        .frame(width: 46, height: 46)
    }

    // MARK: - Content column

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Name
            Text(habit.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(
                    habit.isCompletedToday
                        ? Color.htFgSecondary
                        : Color.htFg
                )
                .strikethrough(habit.isCompletedToday,
                               color: Color.htFgTertiary)
                .lineLimit(1)

            // Sublabel
            sublabel

            // Goal progress bar (amount / nTimes)
            if let goal = habit.goal,
               goal.type == .amount || goal.type == .nTimes {
                DSProgressBar(
                    value: habit.progressTowardGoal(),
                    color: habit.accentColor,
                    height: 3
                )
                .frame(maxWidth: 140)
            }

            // Tags
            if !habit.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(habit.tags.prefix(2)) { tag in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 4, height: 4)
                            Text(tag.label)
                                .font(.system(size: 10))
                                .foregroundStyle(tag.color)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(tag.color.opacity(0.08), in: Capsule())
                    }
                    if habit.tags.count > 2 {
                        Text("+\(habit.tags.count - 2)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.htFgTertiary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sublabel: some View {
        if focusProgress > 0, let session = activeFocusSession {
            // Focus in progress
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 9))
                Text("\(session.elapsedSeconds / 60)m / \(session.durationSeconds / 60)m")
                    .font(.system(size: 11))
            }
            .foregroundStyle(habit.accentColor)
        } else if let goal = habit.goal {
            // Goal sublabel
            Text(habit.goalProgressLabel.isEmpty
                 ? goal.displayTarget : habit.goalProgressLabel)
                .font(.system(size: 11))
                .foregroundStyle(Color.htFgSecondary)
        } else {
            // Frequency + optional focus duration
            HStack(spacing: 4) {
                Text(habit.frequencyLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.htFgSecondary)
                if habit.hasFocusTimer {
                    Text("·")
                        .foregroundStyle(Color.htFgTertiary)
                    Text("\(habit.focusDurationMinutes) min")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.htFgSecondary)
                }
                if habit.currentStreak > 1 {
                    Text("·")
                        .foregroundStyle(Color.htFgTertiary)
                    Text("🔥 \(habit.currentStreak)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.htFireFg)
                }
            }
        }
    }

    // MARK: - Status area (right side)

    @ViewBuilder
    private var statusArea: some View {
        VStack(alignment: .trailing, spacing: 4) {
            statusChip

            // Focus timer icon
            if habit.hasFocusTimer && !habit.isCompletedToday {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.htFgTertiary)
            }
        }
    }

    @ViewBuilder
    private var statusChip: some View {
        if habit.isCompletedToday {
            // Done chip
            Text("Done")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.htDoneFg)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.htDoneBg, in: Capsule())

        } else if let goal = habit.goal, goal.type == .nTimes {
            // Partial count chip e.g. "6 / 8"
            let count = habit.completedDates.filter {
                Calendar.current.isDateInToday($0)
            }.count
            Text("\(count) / \(goal.targetCount)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.htPartialFg)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.htPartialBg, in: Capsule())

        } else if habit.hasFocusTimer && focusProgress > 0,
                  let session = activeFocusSession {
            // Timer chip e.g. "12 min"
            Text("\(session.elapsedSeconds / 60) min")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.htPartialFg)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.htPartialBg, in: Capsule())

        } else {
            // Pending chip
            Text("Pending")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.htPendingFg)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.htPendingBg, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.htBorderC, lineWidth: 0.5)
                )
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            showingDetail = true
        } label: {
            Label("View detail", systemImage: "info.circle")
        }
        Button {
            if !habit.isCompletedToday {
                habit.toggleToday()
                if habit.isCompletedToday {
                    let toast = CompletionToast.make(for: habit)
                    onCompleted?(toast)
                    showingDecoration = true    // ← show decoration here too
                }
                WidgetCenter.shared.reloadAllTimelines()
//                let toast = CompletionToast.make(for: habit)
//                onCompleted?(toast)
//                showingDecoration = true
//                WidgetCenter.shared.reloadAllTimelines()
            }
        } label: {
            Label(
                habit.isCompletedToday ? "Completed" : "Mark complete",
                systemImage: habit.isCompletedToday
                    ? "checkmark.circle.fill" : "checkmark.circle"
            )
        }
        .disabled(habit.isCompletedToday)

        if habit.hasFocusTimer {
            Button { showingFocus = true } label: {
                Label("Focus timer", systemImage: "timer")
            }
        }

        Divider()

        Button { onEdit?() } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) {
            Task { NotificationManager.shared.cancel(for: habit) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Tap

    private func handleTap() {
        // Capture state BEFORE any changes
        let wasCompleted = habit.isCompletedToday

        // If already done — do nothing, user must swipe to undo
        guard !wasCompleted else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(DSAnim.fast) { bouncing = true }

        if habit.hasFocusTimer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.showingFocus = true
                self.bouncing = false
            }
            return
        }

        if let goal = habit.goal, goal.type == .nTimes {
            habit.completedDates.append(Date())
            let reached = habit.progressTowardGoal() >= 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.bouncing = false
                if reached {
                    let toast = CompletionToast.make(for: self.habit)
                    self.onCompleted?(toast)
                    self.showingDecoration = true   // ← only when goal reached
                }
            }
        } else {
            // Toggle → now completed
            habit.toggleToday()
            // Only show decoration if we just completed (not uncompleted)
            if habit.isCompletedToday {
                let toast = CompletionToast.make(for: habit)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.bouncing = false
                    self.onCompleted?(toast)
                    self.showingDecoration = true   // ← only on completion
                }
            } else {
                // Was somehow toggled back — no decoration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.bouncing = false
                }
            }
        }

        WidgetCenter.shared.reloadAllTimelines()
        checkMilestones(context: SharedStore.container.mainContext)
    }
    
    @MainActor
    func checkMilestones(context: ModelContext) {
        let unlocks = MilestoneEngine.shared.check(habit: habit, context: context)
        if !unlocks.isEmpty {
            onMilestoneUnlocked?(unlocks)
            unlocks.forEach {
                NotificationManager.shared.scheduleMilestoneNotification(unlock: $0)
            }
        }
    }
}
