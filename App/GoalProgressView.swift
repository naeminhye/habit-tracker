//
//  GoalProgressView.swift
//  HabitTracker
//
//  Created by JaceyNguyen on 20/04/2026.
//

import SwiftUI

struct GoalProgressRow: View {
    @Bindable var habit: Habit
    @State private var showingAmountEntry = false
    @State private var enteredAmount: Double = 0

    var body: some View {
        guard let goal = habit.goal else { return AnyView(EmptyView()) }

        let progress = habit.progressTowardGoal()
        let ismet = habit.isGoalMetToday

        return AnyView(
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: ismet ? "checkmark.circle.fill" : goal.type.icon)
                        .font(.caption.bold())
                        .foregroundStyle(ismet ? ThemeManager.shared.accentColor : habit.accentColor)

                    Text(habit.goalProgressLabel)
                        .font(.caption.bold())
                        .foregroundStyle(ismet ? ThemeManager.shared.accentColor : habit.accentColor)

                    Spacer()

                    if goal.type == .amount {
                        Button {
                            enteredAmount = 0
                            showingAmountEntry = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                                .foregroundStyle(habit.accentColor)
                        }
                        .buttonStyle(.plain)
                    } else if goal.type == .nTimes {
                        Button {
                            habit.completedDates.append(Date())
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                                .foregroundStyle(habit.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 4)
                        Capsule()
                            .fill(ismet ? Color.green : habit.accentColor)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(response: 0.4), value: progress)
                    }
                }
                .frame(height: 4)
            }
            .sheet(isPresented: $showingAmountEntry) {
                AmountEntrySheet(
                    habit: habit,
                    enteredAmount: $enteredAmount
                )
                .presentationDetents([.height(280)])
            }
        )
    }
}

// MARK: - Amount entry sheet

struct AmountEntrySheet: View {
    @Bindable var habit: Habit
    @Binding var enteredAmount: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current progress
                if let goal = habit.goal {
                    VStack(spacing: 6) {
                        Text(habit.goalProgressLabel)
                            .font(.title2.bold())
                            .foregroundStyle(habit.accentColor)
                        Text("of \(formatAmount(goal.targetAmount)) \(goal.unit) today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Amount stepper
                    HStack(spacing: 20) {
                        Button {
                            if enteredAmount >= 0.5 { enteredAmount -= 0.5 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(habit.accentColor)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 2) {
                            Text(formatAmount(enteredAmount))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text(goal.unit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minWidth: 100)

                        Button {
                            enteredAmount += 0.5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(habit.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    // Quick add chips
                    HStack(spacing: 10) {
                        ForEach([0.25, 0.5, 1.0, 2.0], id: \.self) { v in
                            Button {
                                enteredAmount += v
                            } label: {
                                Text("+\(formatAmount(v))")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Color.secondary.opacity(0.12),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    Button {
                        goal.currentAmount += enteredAmount
                        if habit.progressTowardGoal() >= 1.0 && !habit.isCompletedToday {
                            habit.toggleToday()
                        }
                        dismiss()
                    } label: {
                        Text("Add \(formatAmount(enteredAmount)) \(goal.unit)")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                enteredAmount > 0 ? habit.accentColor : Color.secondary.opacity(0.2),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(enteredAmount <= 0)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Log \(habit.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func formatAmount(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : String(format: "%.1f", v)
    }
}
