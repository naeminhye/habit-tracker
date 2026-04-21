//
//  AchievementsView.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query var badges: [Badge]
    @Query(sort: \Milestone.targetValue) var milestones: [Milestone]
    @Query var habits: [Habit]
    @State private var selectedTab: AchievementTab = .badges
    @State private var showingCustomCreator = false

    enum AchievementTab: String, CaseIterable {
        case badges     = "Badges"
        case milestones = "Milestones"
        case progress   = "Progress"
    }

    var unlockedBadges: [Badge] { badges.filter(\.isUnlocked) }
    var lockedBadges: [Badge]   { badges.filter { !$0.isUnlocked } }
    var reachedMilestones: [Milestone] { milestones.filter(\.isReached) }
    var pendingMilestones: [Milestone] { milestones.filter { !$0.isReached } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsPageBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    heroStrip
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.bottom, DSSpacing.md)
                    tabPicker
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.bottom, DSSpacing.md)
                    DSDivider()
                    ScrollView(showsIndicators: false) {
                        Group {
                            switch selectedTab {
                            case .badges:     badgesContent
                            case .milestones: milestonesContent
                            case .progress:   progressContent
                            }
                        }
                        .padding(.top, DSSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCustomCreator) {
                CustomMilestoneCreator()
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ACHIEVEMENTS")
                    .font(DSFont.overline())
                    .foregroundStyle(Color.dsLabel)
                    .kerning(1)
                Text("\(unlockedBadges.count) badges unlocked")
                    .font(DSFont.displayM())
                    .foregroundStyle(Color.dsIndigo)
            }
            Spacer()
            Button {
                showingCustomCreator = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.dsAccent, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.top, DSSpacing.md)
        .padding(.bottom, DSSpacing.sm)
    }

    // MARK: - Hero strip

    private var heroStrip: some View {
        HStack(spacing: 0) {
            DSStatBadge(
                value: "\(unlockedBadges.count)",
                label: "BADGES",
                color: .dsGold,
                icon: "medal.fill"
            )
            dsVerticalDivider
            DSStatBadge(
                value: "\(reachedMilestones.count)",
                label: "MILESTONES",
                color: .dsMint,
                icon: "flag.fill"
            )
            dsVerticalDivider
            DSStatBadge(
                value: "\(habits.map(\.currentStreak).max() ?? 0)",
                label: "BEST STREAK",
                color: .dsGold,
                icon: "flame.fill"
            )
        }
        .padding(DSSpacing.md)
        .background(Color.dsBackground,
                    in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
    }

    private var dsVerticalDivider: some View {
        Rectangle()
            .fill(Color.dsBorder)
            .frame(width: 1, height: 36)
    }

    // MARK: - Tab picker

    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(AchievementTab.allCases, id: \.self) { tab in
                let isActive = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(DSFont.bodyBold(13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isActive ? Color.dsIndigo : Color.clear,
                            in: RoundedRectangle(cornerRadius: DSRadius.sm)
                        )
                        .foregroundStyle(isActive ? .white : Color.dsLabel)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.dsBorder.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: DSRadius.sm + 4))
    }

    // MARK: - Badges content

    private var badgesContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            if !unlockedBadges.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSSectionHeader(
                        title: "Unlocked",
                        count: unlockedBadges.count
                    )
                    .padding(.horizontal, DSSpacing.lg)

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: DSSpacing.sm),
                            count: 3
                        ),
                        spacing: DSSpacing.sm
                    ) {
                        ForEach(unlockedBadges) { badge in
                            DSBadgeCard(badge: badge, locked: false)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
            }

            if !lockedBadges.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    DSSectionHeader(
                        title: "Locked",
                        count: lockedBadges.count
                    )
                    .padding(.horizontal, DSSpacing.lg)

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: DSSpacing.sm),
                            count: 3
                        ),
                        spacing: DSSpacing.sm
                    ) {
                        ForEach(lockedBadges) { badge in
                            DSBadgeCard(badge: badge, locked: true)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
            }

            if badges.isEmpty {
                dsEmptyState(
                    icon: "medal",
                    title: "No badges yet",
                    subtitle: "Complete habits to unlock badges"
                )
            }
        }
    }

    // MARK: - Milestones content

    private var milestonesContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            if !reachedMilestones.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSSectionHeader(
                        title: "Reached",
                        count: reachedMilestones.count
                    )
                    .padding(.horizontal, DSSpacing.lg)
                    ForEach(reachedMilestones) { milestone in
                        DSMilestoneRow(milestone: milestone, reached: true)
                            .padding(.horizontal, DSSpacing.lg)
                    }
                }
            }

            if !pendingMilestones.isEmpty {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSSectionHeader(
                        title: "Upcoming",
                        count: pendingMilestones.count
                    )
                    .padding(.horizontal, DSSpacing.lg)
                    ForEach(pendingMilestones) { milestone in
                        DSMilestoneRow(milestone: milestone, reached: false)
                            .padding(.horizontal, DSSpacing.lg)
                    }
                }
            }

            if milestones.isEmpty {
                dsEmptyState(
                    icon: "flag",
                    title: "No milestones",
                    subtitle: "Keep completing habits to hit milestones"
                )
            }
        }
    }

    // MARK: - Progress content

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(
                title: "Per-habit",
                count: habits.count
            )
            .padding(.horizontal, DSSpacing.lg)

            ForEach(habits) { habit in
                DSHabitAchievementCard(
                    habit: habit,
                    milestones: milestones
                )
                .padding(.horizontal, DSSpacing.lg)
            }
        }
    }

    // MARK: - Empty state

    private func dsEmptyState(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.dsBorder)
            Text(title)
                .font(DSFont.title())
                .foregroundStyle(Color.dsIndigo)
            Text(subtitle)
                .font(DSFont.body())
                .foregroundStyle(Color.dsLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DSSpacing.xxl)
    }
}

// MARK: - DSBadgeCard

struct DSBadgeCard: View {
    let badge: Badge
    let locked: Bool

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            // Badge medallion
            ZStack {
                Circle()
                    .fill(locked
                          ? Color.dsBorder.opacity(0.4)
                          : Color.dsGold.opacity(0.08))
                    .frame(width: 68, height: 68)

                // Outer ring
                Circle()
                    .strokeBorder(
                        locked
                            ? Color.dsBorder
                            : Color.dsGold,
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: locked ? [4, 3] : []
                        )
                    )
                    .frame(width: 68, height: 68)

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.dsBorder)
                } else {
                    StickerText(
                        text: badge.emoji,
                        fontSize: 34,
                        outlineWidth: 2.5
                    )
                }
            }

            // Name
            Text(badge.name)
                .font(DSFont.bodyBold(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(locked ? Color.dsLabel : Color.dsIndigo)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Date or hint
            if !locked, let date = badge.unlockedAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(DSFont.caption(10))
                    .foregroundStyle(Color.dsLabel)
            } else {
                Text(badge.lockedDescription)
                    .font(DSFont.caption(10))
                    .foregroundStyle(Color.dsLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DSSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            Color.dsBackground,
            in: RoundedRectangle(cornerRadius: DSRadius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(
                    locked
                        ? Color.dsBorder
                        : Color.dsGold.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - DSMilestoneRow

struct DSMilestoneRow: View {
    let milestone: Milestone
    let reached: Bool

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(reached
                          ? Color.dsMint.opacity(0.1)
                          : Color.dsBorder.opacity(0.4))
                    .frame(width: 46, height: 46)
                Circle()
                    .strokeBorder(
                        reached ? ThemeManager.shared.accentColor : Color.dsBorder,
                        lineWidth: 1.5
                    )
                    .frame(width: 46, height: 46)

                if reached {
                    StickerText(
                        text: milestone.emoji,
                        fontSize: 22,
                        outlineWidth: 1.5
                    )
                } else {
                    Text(milestone.emoji)
                        .font(.system(size: 22))
                        .opacity(0.25)
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(milestone.title)
                        .font(DSFont.bodyBold())
                        .foregroundStyle(
                            reached ? Color.dsIndigo : Color.dsLabel
                        )
                    if milestone.isCustom {
                        DSPill(text: "custom", color: .accentColor)
                    }
                }
                Text(milestone.progressDescription)
                    .font(DSFont.caption())
                    .foregroundStyle(Color.dsLabel)
                if reached, let date = milestone.reachedAt {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.dsMint)
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(DSFont.caption(10))
                            .foregroundStyle(Color.dsLabel)
                    }
                }
            }

            Spacer()

            // Target or checkmark
            if reached {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.dsMint)
            } else {
                VStack(spacing: 2) {
                    Text("\(milestone.targetValue)")
                        .font(DSFont.displayL())
                        .foregroundStyle(Color.dsIndigo)
                    Text(milestone.type.displayName.lowercased())
                        .font(DSFont.caption(9))
                        .foregroundStyle(Color.dsLabel)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 44)
            }
        }
        .padding(DSSpacing.md)
        .background(
            Color.dsBackground,
            in: RoundedRectangle(cornerRadius: DSRadius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(
                    reached
                        ? Color.dsMint.opacity(0.3)
                        : Color.dsBorder,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - DSHabitAchievementCard

struct DSHabitAchievementCard: View {
    let habit: Habit
    let milestones: [Milestone]

    private var habitMilestones: [Milestone] {
        milestones.filter {
            $0.habitID == nil || $0.habitID == habit.id
        }
    }

    private var reached: Int {
        habitMilestones.filter(\.isReached).count
    }

    private var total: Int { habitMilestones.count }

    private var nextMilestone: Milestone? {
        habitMilestones.first { !$0.isReached }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            // Header
            HStack(spacing: DSSpacing.md) {
                DSHabitAvatar(
                    emoji: habit.emoji,
                    color: habit.accentColor,
                    size: 44,
                    completed: habit.isCompletedToday
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(DSFont.bodyBold())
                        .foregroundStyle(Color.dsIndigo)
                    HStack(spacing: DSSpacing.sm) {
                        Text("\(habit.totalCompletions) check-ins")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                        DSStreakBadge(streak: habit.currentStreak)
                    }
                }

                Spacer()

                // Milestone fraction
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(reached)/\(total)")
                        .font(DSFont.displayM())
                        .foregroundStyle(habit.accentColor)
                    Text("milestones")
                        .font(DSFont.caption(10))
                        .foregroundStyle(Color.dsLabel)
                }
            }

            // Progress bar
            DSProgressBar(
                value: total > 0 ? Double(reached) / Double(total) : 0,
                color: habit.accentColor,
                height: 5
            )

            // Next milestone
            if let next = nextMilestone {
                HStack(spacing: DSSpacing.sm) {
                    Text(next.emoji)
                        .font(.system(size: 14))
                    Text("Next:")
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel)
                    Text(next.title)
                        .font(DSFont.bodyBold(12))
                        .foregroundStyle(habit.accentColor)
                    Text("· \(next.progressDescription)")
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel)
                        .lineLimit(1)
                }
                .padding(DSSpacing.sm)
                .background(
                    habit.accentColor.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: DSRadius.sm)
                )
            }
        }
        .padding(DSSpacing.md)
        .background(
            Color.dsBackground,
            in: RoundedRectangle(cornerRadius: DSRadius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(Color.dsBorder, lineWidth: 1)
        )
    }
}
