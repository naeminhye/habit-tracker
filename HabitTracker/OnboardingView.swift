//
//  OnboardingView.swift
//  HabitTracker
//
//  Created by BangChitty on 21/04/2026.
//

import SwiftUI
import SwiftData

// MARK: - Onboarding step

enum OnboardingStep: Int, CaseIterable {
    case welcome     = 0
    case interests   = 1
    case firstHabit  = 2
    case permissions = 3
}

// MARK: - Interest category

struct InterestCategory: Identifiable {
    let id: String
    let emoji: String
    let label: String
    let habits: [SuggestedHabit]
}

struct SuggestedHabit: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let accentHex: String
    let frequency: Frequency
    let focusMinutes: Int
}

extension InterestCategory {
    static let all: [InterestCategory] = [
        InterestCategory(id: "health", emoji: "💪", label: "Health & Fitness",
            habits: [
                SuggestedHabit(name: "Morning run", emoji: "🏃", accentHex: "FF6B4A", frequency: .daily, focusMinutes: 30),
                SuggestedHabit(name: "Drink 2L water", emoji: "💧", accentHex: "007AFF", frequency: .daily, focusMinutes: 0),
                SuggestedHabit(name: "Workout", emoji: "🏋️", accentHex: "FF3B30", frequency: .daily, focusMinutes: 45),
            ]),
        InterestCategory(id: "mind", emoji: "🧠", label: "Mind & Learning",
            habits: [
                SuggestedHabit(name: "Read 20 minutes", emoji: "📚", accentHex: "5856D6", frequency: .daily, focusMinutes: 20),
                SuggestedHabit(name: "Meditate", emoji: "🧘", accentHex: "AF52DE", frequency: .daily, focusMinutes: 10),
                SuggestedHabit(name: "Study", emoji: "✍️", accentHex: "FF9500", frequency: .daily, focusMinutes: 25),
            ]),
        InterestCategory(id: "creative", emoji: "🎨", label: "Creative",
            habits: [
                SuggestedHabit(name: "Draw or sketch", emoji: "✏️", accentHex: "FF2D55", frequency: .daily, focusMinutes: 20),
                SuggestedHabit(name: "Practice music", emoji: "🎸", accentHex: "FF9500", frequency: .daily, focusMinutes: 30),
                SuggestedHabit(name: "Journal", emoji: "📝", accentHex: "34C759", frequency: .daily, focusMinutes: 15),
            ]),
        InterestCategory(id: "wellness", emoji: "🌿", label: "Wellness",
            habits: [
                SuggestedHabit(name: "Sleep by 11pm", emoji: "😴", accentHex: "5856D6", frequency: .daily, focusMinutes: 0),
                SuggestedHabit(name: "No phone 1hr before bed", emoji: "📵", accentHex: "636366", frequency: .daily, focusMinutes: 0),
                SuggestedHabit(name: "Gratitude log", emoji: "🙏", accentHex: "FFB547", frequency: .daily, focusMinutes: 5),
            ]),
        InterestCategory(id: "social", emoji: "❤️", label: "Relationships",
            habits: [
                SuggestedHabit(name: "Call family", emoji: "📞", accentHex: "FF2D55", frequency: .weekly, focusMinutes: 0),
                SuggestedHabit(name: "Quality time", emoji: "🫂", accentHex: "FF6B4A", frequency: .weekly, focusMinutes: 0),
                SuggestedHabit(name: "Acts of kindness", emoji: "🌸", accentHex: "FF2D55", frequency: .daily, focusMinutes: 0),
            ]),
        InterestCategory(id: "finance", emoji: "💰", label: "Finance",
            habits: [
                SuggestedHabit(name: "Track expenses", emoji: "💳", accentHex: "34C759", frequency: .daily, focusMinutes: 10),
                SuggestedHabit(name: "No-spend day", emoji: "🏦", accentHex: "00C7BE", frequency: .weekly, focusMinutes: 0),
                SuggestedHabit(name: "Review budget", emoji: "📊", accentHex: "5856D6", frequency: .weekly, focusMinutes: 15),
            ]),
    ]
}

// MARK: - OnboardingView

@MainActor
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Binding var isPresented: Bool

    @State private var step: OnboardingStep = .welcome
    @State private var selectedInterests: Set<String> = []
    @State private var selectedHabits: Set<UUID> = []
    @State private var userName = ""
    @State private var dragOffset: CGFloat = 0
    @State private var animating = false

    private var suggestedHabits: [SuggestedHabit] {
        InterestCategory.all
            .filter { selectedInterests.contains($0.id) }
            .flatMap(\.habits)
    }

    var body: some View {
        ZStack {
            Color.dsPageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.top, DSSpacing.md)

                // Step indicator
                if step != .welcome {
                    stepIndicator
                        .padding(.top, DSSpacing.md)
                }

                // Content
                ZStack {
                    switch step {
                    case .welcome:     welcomeStep
                    case .interests:   interestsStep
                    case .firstHabit:  firstHabitStep
                    case .permissions: permissionsStep
                    }
                }
                .offset(x: dragOffset)
                .animation(.easeOut(duration: 0.2), value: step)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            if v.translation.width > 0 {
                                dragOffset = v.translation.width * 0.3
                            }
                        }
                        .onEnded { v in
                            if v.translation.width > 80 { goBack() }
                            withAnimation { dragOffset = 0 }
                        }
                )

                Spacer(minLength: 0)

                // Bottom CTA
                bottomBar
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.xl)
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            if step != .welcome {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.dsLabel)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                finish()
            } label: {
                Text("Skip")
                    .font(DSFont.secondary())
                    .foregroundStyle(Color.dsLabel)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1..<OnboardingStep.allCases.count, id: \.self) { i in
                let isActive = step.rawValue >= i
                Capsule()
                    .fill(isActive
                          ? ThemeManager.shared.accentColor
                          : Color.dsBorder)
                    .frame(width: isActive ? 20 : 6, height: 6)
                    .animation(.easeOut(duration: 0.2), value: step)
            }
        }
        .padding(.bottom, DSSpacing.sm)
    }

    // MARK: - Welcome step

    private var welcomeStep: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            // App icon preview
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(ThemeManager.shared.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(
                                ThemeManager.shared.accentColor.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
                VStack(spacing: 4) {
                    Text("✅")
                        .font(.system(size: 44))
                }
            }

            VStack(spacing: DSSpacing.sm) {
                Text("Welcome to\nHabitTracker")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                    .multilineTextAlignment(.center)

                Text("Build habits that stick.\nSmall steps, big changes.")
                    .font(DSFont.body())
                    .foregroundStyle(Color.dsLabel)
                    .multilineTextAlignment(.center)
            }

            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you?")
                    .font(DSFont.secondary())
                    .foregroundStyle(Color.dsLabel)

                TextField("Your name (optional)", text: $userName)
                    .font(DSFont.body())
                    .padding(.horizontal, DSSpacing.md)
                    .frame(height: 44)
                    .background(Color.dsCardBackground,
                                in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.dsBorder, lineWidth: 0.5)
                    )
            }
            .padding(.horizontal, DSSpacing.lg)

            Spacer()
        }
    }

    // MARK: - Interests step

    private var interestsStep: some View {
        VStack(spacing: DSSpacing.lg) {
            VStack(spacing: DSSpacing.sm) {
                Text("What matters to you?")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                Text("Pick your interests — we'll suggest habits to get you started.")
                    .font(DSFont.secondary())
                    .foregroundStyle(Color.dsLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.md)

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(),
                                   spacing: DSSpacing.sm), count: 2),
                    spacing: DSSpacing.sm
                ) {
                    ForEach(InterestCategory.all) { cat in
                        interestCell(cat)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.bottom, DSSpacing.lg)
            }
        }
    }

    private func interestCell(_ cat: InterestCategory) -> some View {
        let isSelected = selectedInterests.contains(cat.id)
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                if isSelected {
                    selectedInterests.remove(cat.id)
                } else {
                    selectedInterests.insert(cat.id)
                }
            }
        } label: {
            HStack(spacing: DSSpacing.sm) {
                Text(cat.emoji)
                    .font(.system(size: 22))
                Text(cat.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(
                        isSelected ? ThemeManager.shared.accentColor
                                   : Color.dsPrimaryText
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ThemeManager.shared.accentColor)
                        .font(.system(size: 16))
                }
            }
            .padding(DSSpacing.md)
            .background(
                isSelected
                    ? ThemeManager.shared.accentColor.opacity(0.08)
                    : Color.dsCardBackground,
                in: RoundedRectangle(cornerRadius: DSRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(
                        isSelected
                            ? ThemeManager.shared.accentColor.opacity(0.3)
                            : Color.dsBorder,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - First habit step

    private var firstHabitStep: some View {
        VStack(spacing: DSSpacing.lg) {
            VStack(spacing: DSSpacing.sm) {
                Text("Pick your first habits")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                Text("Select a few to start — you can always add more later.")
                    .font(DSFont.secondary())
                    .foregroundStyle(Color.dsLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.md)

            if suggestedHabits.isEmpty {
                // No interests selected — show generic suggestions
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.sm) {
                        ForEach(InterestCategory.all.first?.habits ?? []) { habit in
                            suggestedHabitRow(habit)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.sm) {
                        ForEach(suggestedHabits) { habit in
                            suggestedHabitRow(habit)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.lg)
                }
            }
        }
    }

    private func suggestedHabitRow(_ suggested: SuggestedHabit) -> some View {
        let isSelected = selectedHabits.contains(suggested.id)
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                if isSelected {
                    selectedHabits.remove(suggested.id)
                } else {
                    selectedHabits.insert(suggested.id)
                }
            }
        } label: {
            HStack(spacing: DSSpacing.md) {
                // Emoji avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: suggested.accentHex).opacity(0.12))
                        .frame(width: 40, height: 40)
                    Text(suggested.emoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggested.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.dsPrimaryText)
                    HStack(spacing: 6) {
                        Text(suggested.frequency.displayName)
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                        if suggested.focusMinutes > 0 {
                            Text("· \(suggested.focusMinutes)m focus")
                                .font(DSFont.caption())
                                .foregroundStyle(Color.dsLabel)
                        }
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? ThemeManager.shared.accentColor
                                : Color.dsBorder,
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(ThemeManager.shared.accentColor)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(DSSpacing.md)
            .background(
                isSelected
                    ? ThemeManager.shared.accentColor.opacity(0.04)
                    : Color.dsCardBackground,
                in: RoundedRectangle(cornerRadius: DSRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(
                        isSelected
                            ? ThemeManager.shared.accentColor.opacity(0.2)
                            : Color.dsBorder,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Permissions step

    private var permissionsStep: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.sm) {
                Text("Almost there!")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                Text("Allow notifications to get reminders\nfor your habits.")
                    .font(DSFont.secondary())
                    .foregroundStyle(Color.dsLabel)
                    .multilineTextAlignment(.center)
            }

            // Permission cards
            VStack(spacing: DSSpacing.sm) {
                permissionCard(
                    icon: "bell.fill",
                    title: "Habit reminders",
                    description: "Get nudged at the right time each day",
                    color: ThemeManager.shared.accentColor
                )
                permissionCard(
                    icon: "trophy.fill",
                    title: "Milestone alerts",
                    description: "Celebrate when you hit streak goals",
                    color: Color.dsGold
                )
            }
            .padding(.horizontal, DSSpacing.lg)

            Spacer()
        }
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        color: Color
    ) -> some View {
        HStack(spacing: DSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                Text(description)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
                .font(.system(size: 20))
        }
        .padding(DSSpacing.md)
        .background(Color.dsCardBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: DSSpacing.sm) {
            // Primary CTA
            Button {
                goNext()
            } label: {
                Text(ctaLabel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        ctaEnabled
                            ? ThemeManager.shared.accentColor
                            : Color.dsBorder,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!ctaEnabled)
            .animation(.easeOut(duration: 0.15), value: ctaEnabled)

            // Step hint
            if step == .interests && selectedInterests.isEmpty {
                Text("Select at least one interest to continue")
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
            }
        }
    }

    private var ctaLabel: String {
        switch step {
        case .welcome:     return "Get started"
        case .interests:   return "Continue"
        case .firstHabit:  return selectedHabits.isEmpty
                                  ? "Skip for now" : "Add \(selectedHabits.count) habit\(selectedHabits.count == 1 ? "" : "s")"
        case .permissions: return "Allow notifications"
        }
    }

    private var ctaEnabled: Bool {
        switch step {
        case .welcome:     return true
        case .interests:   return !selectedInterests.isEmpty
        case .firstHabit:  return true
        case .permissions: return true
        }
    }

    // MARK: - Navigation

    private func goNext() {
        switch step {
        case .welcome:
            withAnimation(.easeOut(duration: 0.2)) {
                step = .interests
            }
        case .interests:
            withAnimation(.easeOut(duration: 0.2)) {
                step = .firstHabit
            }
        case .firstHabit:
            createSelectedHabits()
            withAnimation(.easeOut(duration: 0.2)) {
                step = .permissions
            }
        case .permissions:
            Task {
                _ = await NotificationManager.shared.requestPermission()
                finish()
            }
        }
    }

    private func goBack() {
        guard step.rawValue > 0 else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            step = OnboardingStep(rawValue: step.rawValue - 1) ?? .welcome
        }
    }

    private func createSelectedHabits() {
        let mainContext = SharedStore.container.mainContext
        let habitsToCreate = suggestedHabits
            .isEmpty ? [] : suggestedHabits
            .filter { selectedHabits.contains($0.id) }

        for suggested in habitsToCreate {
            let habit = Habit(
                name: suggested.name,
                emoji: suggested.emoji,
                accentColorHex: suggested.accentHex,
                frequency: suggested.frequency,
                focusDurationMinutes: suggested.focusMinutes
            )
            mainContext.insert(habit)
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        if !userName.isEmpty {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

