//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

@MainActor
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
    @State private var selectedDays: [Int] = [2, 3, 4, 5, 6]
    @State private var showingEmojiPicker = false
    @State private var showingTagManager = false
    @State private var focusDurationMinutes = 0
    @State private var deepFocusEnabled = false
    @State private var enableGoal = false
    @State private var goalType: GoalType = .oncePer
    @State private var goalPeriod: GoalPeriod = .day
    @State private var targetCount: Int = 3
    @State private var targetAmount: Double = 0
    @State private var goalUnit: String = ""
    @State private var startDate: Date = Date()
    @State private var enableEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(
        byAdding: .month, value: 1, to: Date()
    )!
    
    var isEditing: Bool { editingHabit != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                habitSection
                colorSection
                tagsSection
                frequencySection
                schedulingSection
                goalSection
                reminderSection
                focusSection
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
            .onAppear {
                loadHabit()
                // Task { await AppIconGenerator.generate() }
            }
            .animation(.easeInOut(duration: 0.2), value: frequency)
        }
    }
    
    // MARK: - Sections
    
    private var schedulingSection: some View {
        Section {
            DatePicker(
                "Start date",
                selection: $startDate,
                displayedComponents: .date
            )
            
            // Only show end date option for non-daily habits
            if frequency != .daily {
                Toggle("Set end date", isOn: $enableEndDate.animation())
                if enableEndDate {
                    DatePicker(
                        "End date",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }
            }
            
            // Next active date preview
            if frequency != .daily {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.dsLabel)
                        .font(.system(size: 13))
                    Text(nextActiveDateLabel)
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel)
                }
            }
        } header: {
            Text("Schedule")
        }
    }
    
    private var nextActiveDateLabel: String {
        // Preview next active date based on current settings
        let cal = Calendar.current
        var day = cal.startOfDay(
            for: cal.date(byAdding: .day, value: 0, to: startDate)!
        )
        for _ in 0..<60 {
            let weekday = cal.component(.weekday, from: day)
            let matches: Bool
            switch frequency {
            case .daily:
                matches = true
            case .weekly:
                matches = cal.component(.weekday, from: startDate) == weekday
            case .monthly:
                matches = cal.component(.day, from: startDate)
                == cal.component(.day, from: day)
            case .everyNDays:
                let diff = cal.dateComponents(
                    [.day],
                    from: cal.startOfDay(for: startDate),
                    to: day
                ).day ?? 0
                matches = customDays > 0 && diff % customDays == 0
            case .weekdays:
                matches = selectedDays.contains(weekday)
            }
            if matches {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "First active: \(formatter.string(from: day))"
            }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return "No upcoming date found"
    }
    
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
            if frequency == .weekdays {
                WeekdayPicker(selectedDays: $selectedDays)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
    
    private var focusSection: some View {
        Section {
            Toggle("Focus timer", isOn: Binding(
                get: { focusDurationMinutes > 0 },
                set: { focusDurationMinutes = $0 ? 25 : 0 }
            ))
            if focusDurationMinutes > 0 {
                Stepper(
                    "\(focusDurationMinutes) minutes",
                    value: $focusDurationMinutes,
                    in: 5...120,
                    step: 5
                )
                Toggle("Deep focus", isOn: $deepFocusEnabled)
                if deepFocusEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Hides pause, skip, and cancel buttons. Timer cannot be stopped until complete.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Focus")
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
                    deleteHabit()
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
    
    private var goalSection: some View {
        Section {
            GoalSetupView(
                goalType: $goalType,
                goalPeriod: $goalPeriod,
                targetCount: $targetCount,
                targetAmount: $targetAmount,
                unit: $goalUnit,
                enableGoal: $enableGoal
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Goal")
        }
    }
    
    // MARK: - Load
    
    private func loadHabit() {
        guard let h = editingHabit else { return }
        
        if let g = h.goal {
            enableGoal    = true
            goalType      = g.type
            goalPeriod    = g.period
            targetCount   = g.targetCount
            targetAmount  = g.targetAmount
            goalUnit      = g.unit
        }
        
        name             = h.name
        emoji            = h.emoji
        habitDescription = h.habitDescription
        accentColorHex   = h.accentColorHex
        frequency        = h.frequency
        customDays       = h.customDays
        selectedDays     = h.selectedDays
        focusDurationMinutes = h.focusDurationMinutes
        deepFocusEnabled = h.deepFocusEnabled
        startDate      = h.startDate
        enableEndDate  = h.endDate != nil
        endDate        = h.endDate ?? Calendar.current.date(
            byAdding: .month, value: 1, to: Date()
        )!
        enableReminder   = h.reminderTime != nil
        selectedTags     = h.tags
    }
    
    // MARK: - Save / Update / Delete
    
    @MainActor
    private func saveHabit() {
        let mainContext = SharedStore.container.mainContext

        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            habitDescription: habitDescription,
            accentColorHex: accentColorHex,
            frequency: frequency,
            customDays: customDays,
            selectedDays: selectedDays,
            focusDurationMinutes: focusDurationMinutes,
            deepFocusEnabled: deepFocusEnabled,
            startDate: startDate,
            endDate: enableEndDate ? endDate : nil,
            reminderTime: enableReminder ? reminderTime : nil
        )

        // Insert first — must be in context before forming relationships
        mainContext.insert(habit)

        // Re-fetch tags in mainContext then assign
        let tagIDs = selectedTags.map(\.id)
        let fetchedTags: [Tag] = tagIDs.compactMap { id in
            let descriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.id == id }
            )
            return try? mainContext.fetch(descriptor).first
        }
        habit.tags = fetchedTags

        // Goal
        if enableGoal {
            let habitGoal = HabitGoal(
                type: goalType,
                period: goalPeriod,
                targetCount: targetCount,
                targetAmount: targetAmount,
                unit: goalUnit
            )
            mainContext.insert(habitGoal)
            habit.goal = habitGoal
        }

        scheduleIfNeeded(for: habit)
        dismiss()
    }
    
    @MainActor
    private func updateHabit() {
        guard let h = editingHabit else { return }
        let mainContext = SharedStore.container.mainContext

        h.name                 = name.trimmingCharacters(in: .whitespaces)
        h.emoji                = emoji
        h.habitDescription     = habitDescription
        h.accentColorHex       = accentColorHex
        h.frequency            = frequency
        h.customDays           = customDays
        h.selectedDays         = selectedDays
        h.focusDurationMinutes = focusDurationMinutes
        h.deepFocusEnabled     = deepFocusEnabled
        h.startDate            = startDate
        h.endDate              = enableEndDate ? endDate : nil
        h.reminderTime         = enableReminder ? reminderTime : nil

        // Re-fetch tags in mainContext
        let tagIDs = selectedTags.map(\.id)
        let fetchedTags: [Tag] = tagIDs.compactMap { id in
            let descriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.id == id }
            )
            return try? mainContext.fetch(descriptor).first
        }
        h.tags = fetchedTags

        if enableGoal {
            if let g = h.goal {
                g.type         = goalType
                g.period       = goalPeriod
                g.targetCount  = targetCount
                g.targetAmount = targetAmount
                g.unit         = goalUnit
            } else {
                let newGoal = HabitGoal(
                    type: goalType,
                    period: goalPeriod,
                    targetCount: targetCount,
                    targetAmount: targetAmount,
                    unit: goalUnit
                )
                mainContext.insert(newGoal)
                h.goal = newGoal
            }
        } else {
            h.goal = nil
        }

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
