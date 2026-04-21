//
//  GoalSetupView.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI

struct GoalSetupView: View {
    @Binding var goalType: GoalType
    @Binding var goalPeriod: GoalPeriod
    @Binding var targetCount: Int
    @Binding var targetAmount: Double
    @Binding var unit: String
    @Binding var enableGoal: Bool

    private let commonUnits = ["liters", "minutes", "hours", "km", "miles",
                                "pages", "reps", "sets", "glasses", "steps"]

    var body: some View {
        // Toggle
        Toggle("Set a goal", isOn: $enableGoal.animation())

        if enableGoal {
            // Goal type picker
            Picker("Type", selection: $goalType) {
                ForEach(GoalType.allCases, id: \.self) { t in
                    Label(t.displayName, systemImage: t.icon).tag(t)
                }
            }
            .pickerStyle(.menu)

            // Period picker
            Picker("Period", selection: $goalPeriod) {
                ForEach(GoalPeriod.allCases, id: \.self) { p in
                    Text("Per \(p.displayName)").tag(p)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            // Type-specific inputs
            switch goalType {
            case .oncePer:
                goalPreview("Complete once per \(goalPeriod.displayName)")

            case .nTimes:
                Stepper(
                    "\(targetCount) times per \(goalPeriod.displayName)",
                    value: $targetCount,
                    in: 2...100
                )

            case .amount:
                HStack {
                    Text("Target")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("0", value: $targetAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(unit.isEmpty ? "unit" : unit)
                        .foregroundStyle(.secondary)
                }

                // Unit picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(commonUnits, id: \.self) { u in
                            Button {
                                unit = u
                            } label: {
                                Text(u)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        unit == u
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.12),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(unit == u ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }

                        // Custom unit input
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("custom…", text: $unit)
                                .font(.caption)
                                .frame(width: 72)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.08), in: Capsule())
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
    }

    private func goalPreview(_ text: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
