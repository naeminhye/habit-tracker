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
    private var isEditing: Bool { editingHabit != nil }

    // MARK: - State

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var habitDescription = ""
    @State private var accentColorHex = "4A9E8A"
    @State private var frequency: Frequency = .daily
    @State private var customDays = 2
    @State private var selectedDays: [Int] = [2, 3, 4, 5, 6]
    @State private var focusDurationMinutes = 25
    @State private var deepFocusEnabled = false
    @State private var enableGoal = false
    @State private var goalType: GoalType = .nTimes
    @State private var goalPeriod: GoalPeriod = .day
    @State private var targetCount = 1
    @State private var targetAmount = 1.0
    @State private var goalUnit = ""
    @State private var enableReminder = false
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 8, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var startDate = Date()
    @State private var enableEndDate = false
    @State private var endDate = Calendar.current.date(
        byAdding: .month, value: 1, to: Date()
    ) ?? Date()
    @State private var selectedTagIDs: [UUID] = []
    @State private var enableFocusTimer = false

    // UI state
    @State private var showingEmojiPicker = false
    @State private var showingTagManager = false
    @State private var showingMoreColors = false
    @State private var descriptionCount = 0

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.htBg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.lg) {
                        habitCard
                        colorSection
                        tagsSection
                        frequencySection
                        scheduleSection
                        reminderSection
                        focusSection
                        if isEditing { deleteSection }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.top, DSSpacing.md)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.htFgSecondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "Edit habit" : "New habit")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.htFg)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isEditing ? updateHabit() : saveHabit()
                    } label: {
                        Text("Save")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(
                                name.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.htFgTertiary
                                    : Color.htTint
                            )
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView(selectedTagIDs: $selectedTagIDs)
            }
            .sheet(isPresented: $showingMoreColors) {
                moreColorsSheet
            }
        }
        .onAppear { if isEditing { loadHabit() } }
    }

    // MARK: - Habit card (emoji + name + description)

    private var habitCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: DSSpacing.md) {
                // Emoji picker square
                Button {
                    showingEmojiPicker = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: accentColorHex).opacity(0.12))
                            .frame(width: 56, height: 56)
                        Text(emoji)
                            .font(.system(size: 28))
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    // Name field
                    TextField("Name", text: $name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.htFg)
                        .onChange(of: name) { _, v in
                            if v.count > 64 {
                                name = String(v.prefix(64))
                            }
                        }

                    DSDivider()

                    // Description field
                    ZStack(alignment: .topLeading) {
                        if habitDescription.isEmpty {
                            Text("Description (optional)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.htFgTertiary)
                        }
                        TextEditor(text: $habitDescription)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.htFgSecondary)
                            .frame(minHeight: 40, maxHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .onChange(of: habitDescription) { _, v in
                                descriptionCount = v.count
                                if v.count > 256 {
                                    habitDescription = String(v.prefix(256))
                                }
                            }
                    }

                    // Character counter at 200+
                    if descriptionCount >= 200 {
                        Text("\(descriptionCount) / 256")
                            .font(.system(size: 10))
                            .foregroundStyle(
                                descriptionCount > 240
                                    ? Color.htMissedFg
                                    : Color.htFgTertiary
                            )
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(DSSpacing.s3)
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Color accent

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HTOverline(text: "Color accent")

            HStack(spacing: 0) {
                HStack(spacing: DSSpacing.md) {
                    ForEach(quickColors, id: \.1) { name, hex in
                        colorDot(hex: hex)
                    }
                }
                .padding(DSSpacing.s3)

                Spacer()

                Button {
                    showingMoreColors = true
                } label: {
                    Text("More colors →")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.htTint)
                }
                .buttonStyle(.plain)
                .padding(.trailing, DSSpacing.s3)
            }
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    private func colorDot(hex: String) -> some View {
        let isSelected = accentColorHex == hex
        return Button {
            withAnimation(DSAnim.base) { accentColorHex = hex }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .strokeBorder(Color.htFg, lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }

    private let quickColors: [(String, String)] = [
        ("Teal",       "4A9E8A"),
        ("Coral",      "CC6B5A"),
        ("Blue",       "4A7ECC"),
        ("Indigo",     "6A5ECC"),
        ("Mint",       "3E9E70"),
        ("Orange",     "B87840"),
    ]

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HTOverline(text: "Tags")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Existing selected tags
                    let displayTags: [Tag] = selectedTagIDs.compactMap { id in
                        try? SharedStore.container.mainContext.fetch(
                            FetchDescriptor<Tag>(
                                predicate: #Predicate { $0.id == id }
                            )
                        ).first
                    }

                    ForEach(displayTags) { tag in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 5, height: 5)
                            Text(tag.label)
                                .font(.system(size: 12))
                                .foregroundStyle(tag.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(tag.color.opacity(0.08), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(tag.color.opacity(0.2),
                                              lineWidth: 0.5)
                        )
                    }

                    // + Add tag dashed chip
                    Button {
                        showingTagManager = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .medium))
                            Text("Add tag")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(Color.htTint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.htSurface, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    style: StrokeStyle(
                                        lineWidth: 1,
                                        dash: [4, 3]
                                    )
                                )
                                .foregroundStyle(Color.htTint.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DSSpacing.s3)
                .padding(.vertical, DSSpacing.s2)
            }
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Frequency (radio-style cards)

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HTOverline(text: "Frequency")

            VStack(spacing: 0) {
                frequencyRow(.daily,     label: "Every day")
                DSDivider().padding(.horizontal, DSSpacing.s3)
                frequencyRow(.weekdays,  label: "Specific days")
                if frequency == .weekdays {
                    weekdayExpansion
                    DSDivider().padding(.horizontal, DSSpacing.s3)
                }
                DSDivider().padding(.horizontal, DSSpacing.s3)
                frequencyRow(.everyNDays, label: "Every N days")
                if frequency == .everyNDays {
                    nDaysExpansion
                    DSDivider().padding(.horizontal, DSSpacing.s3)
                }
                DSDivider().padding(.horizontal, DSSpacing.s3)
                frequencyRow(.weekly,    label: "Weekly")
                DSDivider().padding(.horizontal, DSSpacing.s3)
                frequencyRow(.monthly,   label: "Monthly")
            }
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    private func frequencyRow(_ f: Frequency, label: String) -> some View {
        let isSelected = frequency == f
        return Button {
            withAnimation(DSAnim.base) { frequency = f }
        } label: {
            HStack(spacing: 12) {
                // Radio dot
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.htTint : Color.htBorderC,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                        .frame(width: 18, height: 18)
                    if isSelected {
                        Circle()
                            .fill(Color.htTint)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.htFg)

                Spacer()
            }
            .frame(height: 44)
            .padding(.horizontal, DSSpacing.s3)
            .background(
                isSelected ? Color.htTintSofter : Color.clear
            )
        }
        .buttonStyle(.plain)
    }

    private var weekdayExpansion: some View {
        WeekdayPicker(selectedDays: $selectedDays)
            .padding(DSSpacing.s3)
            .background(Color.htSurfaceAlt)
    }

    private var nDaysExpansion: some View {
        HStack {
            Text("Every")
                .font(.system(size: 13))
                .foregroundStyle(Color.htFgSecondary)
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if customDays > 2 { customDays -= 1 }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.htTint)
                }
                .buttonStyle(.plain)

                Text("\(customDays)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.htFg)
                    .frame(minWidth: 24)

                Button {
                    customDays += 1
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.htTint)
                }
                .buttonStyle(.plain)
            }
            Text("days")
                .font(.system(size: 13))
                .foregroundStyle(Color.htFgSecondary)
        }
        .padding(DSSpacing.s3)
        .background(Color.htSurfaceAlt)
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HTOverline(text: "Schedule")

            VStack(spacing: 0) {
                // Start date
                HStack {
                    Text("Start date")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.htFg)
                    Spacer()
                    DatePicker("", selection: $startDate,
                               displayedComponents: .date)
                        .labelsHidden()
                        .font(.system(size: 13))
                }
                .frame(height: 44)
                .padding(.horizontal, DSSpacing.s3)

                DSDivider().padding(.horizontal, DSSpacing.s3)

                // End date toggle
                HStack {
                    Text("End date")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.htFg)
                    Spacer()
                    if enableEndDate {
                        DatePicker("", selection: $endDate,
                                   in: startDate...,
                                   displayedComponents: .date)
                            .labelsHidden()
                            .font(.system(size: 13))
                    } else {
                        Button {
                            withAnimation(DSAnim.base) {
                                enableEndDate = true
                            }
                        } label: {
                            Text("No end date")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.htTint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, DSSpacing.s3)
            }
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HTOverline(text: "Reminder")

            VStack(spacing: 0) {
                HStack {
                    Text("Daily reminder")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.htFg)
                    Spacer()
                    Toggle("", isOn: $enableReminder.animation(DSAnim.base))
                        .tint(Color.htTint)
                        .labelsHidden()
                }
                .frame(height: 44)
                .padding(.horizontal, DSSpacing.s3)

                if enableReminder {
                    DSDivider().padding(.horizontal, DSSpacing.s3)
                    HStack {
                        Text("Time")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.htFg)
                        Spacer()
                        DatePicker("", selection: $reminderTime,
                                   displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .frame(height: 44)
                    .padding(.horizontal, DSSpacing.s3)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Focus timer

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HTOverline(text: "Focus timer")

            VStack(spacing: 0) {
                HStack {
                    Text("Enable focus timer")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.htFg)
                    Spacer()
                    Toggle("",
                           isOn: $enableFocusTimer.animation(DSAnim.base))
                        .tint(Color.htTint)
                        .labelsHidden()
                }
                .frame(height: 44)
                .padding(.horizontal, DSSpacing.s3)

                if enableFocusTimer {
                    DSDivider().padding(.horizontal, DSSpacing.s3)

                    // Duration stepper
                    HStack {
                        Text("Default duration")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.htFg)
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if focusDurationMinutes > 5 {
                                    focusDurationMinutes = max(
                                        5, focusDurationMinutes - 5
                                    )
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.htTint)
                            }
                            .buttonStyle(.plain)

                            Text("\(focusDurationMinutes) min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.htFg)
                                .frame(minWidth: 52)

                            Button {
                                if focusDurationMinutes < 120 {
                                    focusDurationMinutes = min(
                                        120, focusDurationMinutes + 5
                                    )
                                }
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.htTint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(height: 44)
                    .padding(.horizontal, DSSpacing.s3)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    DSDivider().padding(.horizontal, DSSpacing.s3)

                    // Deep focus toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deep focus")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.htFg)
                            Text("Locks the screen until done")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.htFgTertiary)
                        }
                        Spacer()
                        Toggle("", isOn: $deepFocusEnabled)
                            .tint(Color.htTint)
                            .labelsHidden()
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, DSSpacing.s3)
                    .padding(.vertical, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Delete (edit mode only)

    private var deleteSection: some View {
        Button(role: .destructive) {
            Task { @MainActor in deleteHabit() }
        } label: {
            Text("Delete habit")
                .font(.system(size: 13))
                .foregroundStyle(Color.htMissedFg)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, DSSpacing.sm)
    }

    // MARK: - More colors sheet

    private var moreColorsSheet: some View {
        NavigationStack {
            ZStack {
                Color.htBg.ignoresSafeArea()
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()),
                                   count: 6),
                    spacing: DSSpacing.lg
                ) {
                    ForEach(allColors, id: \.1) { name, hex in
                        colorDot(hex: hex)
                    }
                }
                .padding(DSSpacing.lg)
            }
            .navigationTitle("Color accent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingMoreColors = false }
                        .foregroundStyle(Color.htTint)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private let allColors: [(String, String)] = [
        ("Teal",     "4A9E8A"), ("Coral",   "CC6B5A"),
        ("Orange",   "B87840"), ("Yellow",  "8C8A30"),
        ("Mint",     "3E9E70"), ("Green",   "3A9E7A"),
        ("Blue",     "4A7ECC"), ("Indigo",  "6A5ECC"),
        ("Purple",   "8A4ECC"), ("Pink",    "CC4A7A"),
        ("Brown",    "7A6050"), ("Graphite","7A7A72"),
    ]

    // MARK: - Load / Save / Update / Delete

    private func loadHabit() {
        guard let h = editingHabit else { return }
        name                  = h.name
        emoji                 = h.emoji
        habitDescription      = h.habitDescription
        accentColorHex        = h.accentColorHex
        frequency             = h.frequency
        customDays            = h.customDays
        selectedDays          = h.selectedDays
        focusDurationMinutes  = h.focusDurationMinutes > 0
                                    ? h.focusDurationMinutes : 25
        deepFocusEnabled      = h.deepFocusEnabled
        enableFocusTimer      = h.focusDurationMinutes > 0
        enableReminder        = h.reminderTime != nil
        reminderTime          = h.reminderTime ?? reminderTime
        startDate             = h.startDate
        enableEndDate         = h.endDate != nil
        endDate               = h.endDate ?? endDate
        selectedTagIDs        = h.tags.map(\.id)
        if let g = h.goal {
            enableGoal    = true
            goalType      = g.type
            goalPeriod    = g.period
            targetCount   = g.targetCount
            targetAmount  = g.targetAmount
            goalUnit      = g.unit
        }
    }

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
            focusDurationMinutes: enableFocusTimer ? focusDurationMinutes : 0,
            deepFocusEnabled: deepFocusEnabled,
            startDate: startDate,
            endDate: enableEndDate ? endDate : nil,
            reminderTime: enableReminder ? reminderTime : nil
        )
        mainContext.insert(habit)

        // Tags
        habit.tags = selectedTagIDs.compactMap { id in
            try? mainContext.fetch(
                FetchDescriptor<Tag>(predicate: #Predicate { $0.id == id })
            ).first
        }

        // Goal
        if enableGoal {
            let g = HabitGoal(
                type: goalType, period: goalPeriod,
                targetCount: targetCount,
                targetAmount: targetAmount, unit: goalUnit
            )
            mainContext.insert(g)
            habit.goal = g
        }

        scheduleIfNeeded(for: habit)
        dismiss()
    }

    @MainActor
    private func updateHabit() {
        guard let h = editingHabit else { return }
        let mainContext = SharedStore.container.mainContext

        h.name                = name.trimmingCharacters(in: .whitespaces)
        h.emoji               = emoji
        h.habitDescription    = habitDescription
        h.accentColorHex      = accentColorHex
        h.frequency           = frequency
        h.customDays          = customDays
        h.selectedDays        = selectedDays
        h.focusDurationMinutes = enableFocusTimer ? focusDurationMinutes : 0
        h.deepFocusEnabled    = deepFocusEnabled
        h.startDate           = startDate
        h.endDate             = enableEndDate ? endDate : nil
        h.reminderTime        = enableReminder ? reminderTime : nil

        h.tags = selectedTagIDs.compactMap { id in
            try? mainContext.fetch(
                FetchDescriptor<Tag>(predicate: #Predicate { $0.id == id })
            ).first
        }

        if enableGoal {
            if let g = h.goal {
                g.type = goalType; g.period = goalPeriod
                g.targetCount = targetCount
                g.targetAmount = targetAmount; g.unit = goalUnit
            } else {
                let g = HabitGoal(
                    type: goalType, period: goalPeriod,
                    targetCount: targetCount,
                    targetAmount: targetAmount, unit: goalUnit
                )
                mainContext.insert(g)
                h.goal = g
            }
        } else {
            h.goal = nil
        }

        NotificationManager.shared.cancel(for: h)
        scheduleIfNeeded(for: h)
        dismiss()
    }

    @MainActor
    private func deleteHabit() {
        guard let h = editingHabit else { return }
        NotificationManager.shared.cancel(for: h)
        if let g = h.goal {
            SharedStore.container.mainContext.delete(g)
        }
        SharedStore.container.mainContext.delete(h)
        dismiss()
    }

    private func scheduleIfNeeded(for habit: Habit) {
        guard enableReminder else { return }
        NotificationManager.shared.schedule(for: habit)
    }
}
