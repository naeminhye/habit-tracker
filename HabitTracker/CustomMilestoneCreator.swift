//
//  CustomMilestoneCreator.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI
import SwiftData

struct CustomMilestoneCreator: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query var habits: [Habit]

    @State private var title = ""
    @State private var emoji = "🎯"
    @State private var type: MilestoneType = .totalCount
    @State private var targetValue = 10
    @State private var selectedHabit: Habit? = nil
    @State private var showingEmojiPicker = false

    var body: some View {
        NavigationStack {
            Form {
                detailSection
                typeSection
                targetSection
                habitSection
            }
            .navigationTitle("New Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMilestone() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }

    // MARK: - Sections

    private var detailSection: some View {
        Section {
            HStack(spacing: 14) {
                Button {
                    showingEmojiPicker = true
                } label: {
                    Text(emoji)
                        .font(.system(size: 36))
                        .frame(width: 56, height: 56)
                        .background(
                            Color.accentColor.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
                .buttonStyle(.plain)
                TextField("Milestone name", text: $title)
                    .font(.body.bold())
            }
            .padding(.vertical, 4)
        } header: {
            Text("Details")
        }
    }

    private var typeSection: some View {
        Section {
            ForEach([MilestoneType.streak, .totalCount, .goalReached], id: \.self) { t in
                let isSelected = type == t
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.displayName)
                            .font(.body)
                        Text(t.hint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { type = t }
            }
        } header: {
            Text("Type")
        }
    }

    private var targetSection: some View {
        Section {
            Stepper(
                targetLabel,
                value: $targetValue,
                in: 1...1000
            )
        } header: {
            Text("Target")
        }
    }

    private var habitSection: some View {
        Section {
            Button {
                selectedHabit = nil
            } label: {
                HStack {
                    Text("Any habit")
                    Spacer()
                    if selectedHabit == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            ForEach(habits) { habit in
                Button {
                    selectedHabit = habit
                } label: {
                    HStack {
                        Text(habit.emoji)
                        Text(habit.name)
                        Spacer()
                        if selectedHabit?.id == habit.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        } header: {
            Text("Apply to")
        }
    }

    // MARK: - Helpers

    private var targetLabel: String {
        switch type {
        case .streak:     return "\(targetValue) days in a row"
        case .totalCount: return "\(targetValue) total check-ins"
        case .goalReached: return "\(targetValue) goals met"
        case .custom:     return "\(targetValue) times"
        }
    }

    private func saveMilestone() {
        let milestone = Milestone(
            title: title.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            type: type,
            targetValue: targetValue,
            habitID: selectedHabit?.id,
            habitName: selectedHabit?.name,
            isCustom: true
        )
        context.insert(milestone)
        dismiss()
    }
}

// MARK: - MilestoneType helpers

extension MilestoneType {
    var displayName: String {
        switch self {
        case .streak:      return "Streak"
        case .totalCount:  return "Total check-ins"
        case .goalReached: return "Goals reached"
        case .custom:      return "Custom"
        }
    }

    var hint: String {
        switch self {
        case .streak:      return "Consecutive days completed"
        case .totalCount:  return "All-time completions"
        case .goalReached: return "Times goal was fully met"
        case .custom:      return "Custom condition"
        }
    }
}
