//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editingHabit: Habit? = nil

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var habitDescription = ""
    @State private var accentColorHex = "007AFF"
    @State private var frequency: Frequency = .daily
    @State private var customDays = 2
    @State private var enableReminder = false
    @State private var reminderTime = Date()
    @State private var selectedTags: [Tag] = []
    @State private var showingEmojiPicker = false
    @State private var showingTagManager = false

    var isEditing: Bool { editingHabit != nil }

    var body: some View {
        NavigationStack {
            Form {
                habitSection
                colorSection
                tagsSection
                frequencySection
                reminderSection
                saveSection
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView(selectedTags: $selectedTags)
            }
            .onAppear { loadHabit() }
            .animation(.easeInOut(duration: 0.2), value: frequency)
        }
    }

    // MARK: - Sections

    private var habitSection: some View {
        Section {
            HStack(spacing: 14) {
                Button {
                    showingEmojiPicker = true
                } label: {
                    Text(emoji)
                        .font(.system(size: 40))
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: accentColorHex).opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: accentColorHex).opacity(0.4), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Name", text: $name)
                        .font(.body.bold())
                    TextField("Description (optional)", text: $habitDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Habit")
        }
    }

    private var colorSection: some View {
        Section {
            HabitColorPicker(selectedHex: $accentColorHex)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        } header: {
            Text("Accent color")
        }
    }

    private var tagsSection: some View {
        Section {
            if selectedTags.isEmpty {
                Button {
                    showingTagManager = true
                } label: {
                    Label("Add tags", systemImage: "tag")
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedTags) { tag in
                            TagBadge(tag: tag)
                        }
                        Button {
                            showingTagManager = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        } header: {
            Text("Tags")
        }
    }

    private var frequencySection: some View {
        Section {
            ForEach(Frequency.allCases, id: \.self) { (f: Frequency) in
                let isSelected = frequency == f
                HStack {
                    Text(f.displayName)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { frequency = f }
            }
            if frequency == .everyNDays {
                HStack {
                    Text("Repeat every")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Stepper("\(customDays) days", value: $customDays, in: 2...30)
                        .fixedSize()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        } header: {
            Text("Frequency")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Enable reminder", isOn: $enableReminder.animation())
            if enableReminder {
                DatePicker(
                    "Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Reminder")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                if isEditing {
                    Task { @MainActor in updateHabit() }
                } else {
                    saveHabit()
                }
            } label: {
                HStack {
                    Spacer()
                    Text(isEditing ? "Save Changes" : "Add Habit")
                        .bold()
                    Spacer()
                }
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

            if isEditing {
                Button(role: .destructive) {
                    Task { @MainActor in deleteHabit() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Habit")
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Load

    private func loadHabit() {
        guard let h = editingHabit else { return }
        name             = h.name
        emoji            = h.emoji
        habitDescription = h.habitDescription
        accentColorHex   = h.accentColorHex
        frequency        = h.frequency
        customDays       = h.customDays
        enableReminder   = h.reminderTime != nil
        reminderTime     = h.reminderTime ?? Date()
        selectedTags     = h.tags
    }

    // MARK: - Save / Update / Delete

    private func saveHabit() {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            habitDescription: habitDescription,
            accentColorHex: accentColorHex,
            frequency: frequency,
            customDays: customDays,
            reminderTime: enableReminder ? reminderTime : nil,
            tags: selectedTags
        )
        context.insert(habit)
        scheduleIfNeeded(for: habit)
        dismiss()
    }

    @MainActor private func updateHabit() {
        guard let h = editingHabit else { return }
        h.name             = name.trimmingCharacters(in: .whitespaces)
        h.emoji            = emoji
        h.habitDescription = habitDescription
        h.accentColorHex   = accentColorHex
        h.frequency        = frequency
        h.customDays       = customDays
        h.reminderTime     = enableReminder ? reminderTime : nil
        h.tags             = selectedTags
        NotificationManager.shared.cancel(for: h)
        scheduleIfNeeded(for: h)
        dismiss()
    }

    @MainActor private func deleteHabit() {
        guard let h = editingHabit else { return }
        NotificationManager.shared.cancel(for: h)
        context.delete(h)
        dismiss()
    }

    private func scheduleIfNeeded(for habit: Habit) {
        guard enableReminder else { return }
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                await MainActor.run {
                    NotificationManager.shared.schedule(for: habit)
                }
            }
        }
    }
}
