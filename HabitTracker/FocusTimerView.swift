//
//  FocusTimerView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData
import UIKit

extension FocusTimerView {
    func requestGuidedAccess() {
        UIAccessibility.requestGuidedAccessSession(enabled: true) { success in
            if !success {
                print("Guided Access not enabled in Settings")
            }
        }
    }

    func endGuidedAccess() {
        UIAccessibility.requestGuidedAccessSession(enabled: false) { _ in }
    }
}

@MainActor
struct FocusTimerView: View {
    @Bindable var habit: Habit
    var existingSession: FocusSession? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var session: FocusSession? = nil
    @State private var timer: Timer? = nil
    @State private var isPaused = false
    @State private var showingDecoration = false
    @State private var showingCancel = false
    @State private var pulseRing = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showLockedMessage = false
    @State private var adjustedMinutes: Int = 0
    @State private var hasStarted = false
    
    private var totalSeconds: Int {
        existingSession?.durationSeconds ?? (adjustedMinutes * 60)
    }
    private var isDeep: Bool { habit.deepFocusEnabled }
    private var isRunning: Bool {
        session != nil && session?.isCompleted == false
    }
    
    var body: some View {
        ZStack {
            (isDeep && hasStarted ? Color.black : Color(.systemBackground))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: hasStarted)
            
            if !hasStarted {
                preSessionView
            } else {
                sessionView
            }
        }
        .onAppear {
            adjustedMinutes = habit.focusDurationMinutes
            if existingSession != nil {
                // Skip pre-session screen, jump straight to timer
                hasStarted = true
                startSession()
            }
        }
        .onDisappear { timer?.invalidate() }
        .interactiveDismissDisabled(hasStarted && isRunning && isDeep)
        .confirmationDialog(
            "End focus session?",
            isPresented: $showingCancel,
            titleVisibility: .visible
        ) {
            Button("End session", role: .destructive) {
                endSession(completed: false)
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingDecoration) {
            DecorationPickerView(date: Date(), habit: habit) {
                dismiss()
            }
        }
        .preferredColorScheme(isDeep && hasStarted ? .dark : nil)
        .statusBarHidden(isDeep && hasStarted)
    }
    
    // MARK: - Blocker bar (deep focus)
    
    private var blockerBar: some View {
        Color.clear
            .frame(height: 60)
            .contentShape(Rectangle())
            .onTapGesture {
                triggerLockedFeedback()
            }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            StickerText(text: habit.emoji, fontSize: 44, outlineWidth: 3)
            Text(habit.name)
                .font(.title3.bold())
                .foregroundStyle(isDeep && isRunning ? .white : .primary)
            HStack(spacing: 6) {
                if isDeep {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text("Focus session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Pre-session
    
    private var preSessionView: some View {
        ZStack {
            Color.dsPageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.dsLabel)
                            .frame(width: 36, height: 36)
                            .background(Color.dsBorder.opacity(0.4), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if isDeep {
                        DSPill(text: "DEEP FOCUS", color: .dsIndigo, filled: true)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.md)

                Spacer()

                // Habit info
                VStack(spacing: DSSpacing.sm) {
                    DSHabitAvatar(
                        emoji: habit.emoji,
                        color: habit.accentColor,
                        size: 80
                    )
                    Text(habit.name)
                        .font(DSFont.displayM())
                        .foregroundStyle(Color.dsIndigo)
                        .lineLimit(2)                    // ← max 2 lines
                        .multilineTextAlignment(.center)
                        .truncationMode(.tail)

                    if !habit.habitDescription.isEmpty {
                        Text(habit.habitDescription)
                            .font(DSFont.body())
                            .foregroundStyle(Color.dsLabel)
                            .lineLimit(2)                // ← max 2 lines
                            .multilineTextAlignment(.center)
                            .truncationMode(.tail)
                    }
                    DSStreakBadge(streak: habit.currentStreak, large: true)
                }
                .padding(.bottom, DSSpacing.xl)

                // Duration picker card
                VStack(spacing: DSSpacing.md) {
                    Text("DURATION")
                        .font(DSFont.overline())
                        .foregroundStyle(Color.dsLabel)
                        .kerning(1)

                    HStack(spacing: DSSpacing.xl) {
                        Button {
                            if adjustedMinutes > 5 { adjustedMinutes -= 5 }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.dsIndigo)
                                .frame(width: 44, height: 44)
                                .background(Color.dsBorder.opacity(0.5), in: Circle())
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 2) {
                            Text("\(adjustedMinutes)")
                                .font(.system(size: 64,
                                              weight: .bold,
                                              design: .rounded))
                                .foregroundStyle(Color.dsIndigo)
                                .monospacedDigit()
                            Text("minutes")
                                .font(DSFont.overline())
                                .foregroundStyle(Color.dsLabel)
                                .kerning(0.5)
                        }
                        .frame(minWidth: 110)

                        Button {
                            if adjustedMinutes < 120 { adjustedMinutes += 5 }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.dsIndigo)
                                .frame(width: 44, height: 44)
                                .background(Color.dsBorder.opacity(0.5), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Presets
                    HStack(spacing: DSSpacing.sm) {
                        ForEach([5, 15, 25, 45, 60], id: \.self) { m in
                            Button {
                                adjustedMinutes = m
                            } label: {
                                Text("\(m)m")
                                    .font(DSFont.bodyBold(12))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        adjustedMinutes == m
                                            ? Color.dsIndigo
                                            : Color.dsBorder.opacity(0.5),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        adjustedMinutes == m ? .white : Color.dsLabel
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(DSSpacing.lg)
                .background(Color.dsBackground,
                            in: RoundedRectangle(cornerRadius: DSRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.lg)
                        .strokeBorder(Color.dsBorder, lineWidth: 1)
                )
                .padding(.horizontal, DSSpacing.lg)

                if isDeep {
                    HStack(spacing: DSSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dsIndigo)
                        Text("Deep focus — no pausing or exiting until done")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, DSSpacing.sm)
                    .background(
                        Color.dsIndigo.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: DSRadius.sm)
                    )
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.top, DSSpacing.md)
                }

                Spacer()

                // Start button
                DSButton(
                    title: "Start Focus",
                    icon: "play.fill",
                    color: habit.accentColor
                ) {
                    withAnimation(.spring(response: 0.4)) {
                        hasStarted = true
                        startSession()
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.bottom, DSSpacing.xxl)
            }
        }
    }
    
    private func presetChip(_ minutes: Int) -> some View {
        let isSelected = adjustedMinutes == minutes
        return Button {
            adjustedMinutes = minutes
        } label: {
            Text("\(minutes)m")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? habit.accentColor : Color.secondary.opacity(0.12),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private var sessionView: some View {
        ZStack {
            (isDeep ? Color.dsAccent : Color.dsSurface)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: isDeep)

            VStack(spacing: 0) {
                // Header
                HStack {
                    DSHabitAvatar(
                        emoji: habit.emoji,
                        color: isDeep ? habit.accentColor : habit.accentColor,
                        size: 36
                    )
                    if !isDeep {
                        Button {
                            pauseAndExit()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.dsLabel)
                        }
                        .buttonStyle(.plain)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(habit.name)
                            .font(DSFont.bodyBold())
                            .foregroundStyle(
                                isDeep ? Color.white : Color.dsIndigo
                            )
                        Text("Focus session")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                    }
                    Spacer()
                    if isDeep && isRunning {
                        DSPill(text: "DEEP", color: .dsGold, filled: true)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.md)

                Spacer()

                // Timer ring
                timerRing
                    .frame(width: 260, height: 260)
                    .offset(x: shakeOffset)

                // Deep focus message
                if isDeep && isRunning {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dsGold)
                        Text("Deep focus active")
                            .font(DSFont.bodyBold(13))
                            .foregroundStyle(Color.dsGold)
                        Text("Stay focused. You've got this.")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                    }
                    .padding(.top, DSSpacing.lg)
                }

                if showLockedMessage {
                    Text("Session is locked — keep going!")
                        .font(DSFont.bodyBold(12))
                        .foregroundStyle(Color.dsGold)
                        .padding(.horizontal, DSSpacing.md)
                        .padding(.vertical, DSSpacing.sm)
                        .background(
                            Color.dsGold.opacity(0.12),
                            in: Capsule()
                        )
                        .padding(.top, DSSpacing.sm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                controls
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.xxl)
            }

            if isDeep && isRunning {
                VStack {
                    blockerBar
                    Spacer()
                    blockerBar
                }
            }
        }
    }
    
    // MARK: - Timer ring
    
    private var timerRing: some View {
        let progress = session?.progress ?? 0
        let remaining = session?.formattedRemaining ?? formatTime(totalSeconds)
        let isComplete = session?.isCompleted == true

        return ZStack {
            // Track
            Circle()
                .stroke(Color.dsBorder, lineWidth: 10)

            // Pulse
            if !isPaused && isRunning {
                Circle()
                    .stroke(habit.accentColor.opacity(0.2), lineWidth: 12)
                    .scaleEffect(pulseRing ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseRing
                    )
                    .onAppear { pulseRing = true }
            }

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isComplete ? ThemeManager.shared.accentColor : habit.accentColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            // Center content
            VStack(spacing: DSSpacing.sm) {
                Text(remaining)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        isComplete ? Color.dsMint :
                        isDeep && isRunning ? .white : Color.dsIndigo
                    )

                if let s = session, !s.isCompleted {
                    Text(isPaused ? "PAUSED" : "FOCUSING")
                        .font(DSFont.overline())
                        .foregroundStyle(Color.dsLabel)
                        .kerning(1)
                } else if isComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.dsMint)
                        Text("COMPLETE")
                            .font(DSFont.overline())
                            .foregroundStyle(Color.dsMint)
                            .kerning(1)
                    }
                }
            }
        }
    }
    // MARK: - Controls
    
    private var controls: some View {
        Group {
            if let s = session, s.isCompleted {
                HStack(spacing: DSSpacing.md) {
                    DSButton(
                        title: "Decorate",
                        icon: "sparkles",
                        color: habit.accentColor,
                        fullWidth: false
                    ) {
                        showingDecoration = true
                    }

                    DSButton(
                        title: "Done",
                        icon: nil,
                        color: Color.dsIndigo,
                        fullWidth: false
                    ) {
                        dismiss()
                    }
                }
            } else if isDeep {
                VStack(spacing: DSSpacing.md) {
                    Button {
                        triggerLockedFeedback()
                    } label: {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.dsGold)
                            .frame(width: 60, height: 60)
                            .background(
                                Color.dsGold.opacity(0.12),
                                in: Circle()
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        Color.dsGold.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Text("Hold 5s to exit")
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel.opacity(0.5))
                        .onLongPressGesture(minimumDuration: 5) {
                            endSession(completed: false)
                        }
                }
            } else {
                HStack(spacing: DSSpacing.lg) {
                    // Cancel
                    Button {
                        showingCancel = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.dsLabel)
                            .frame(width: 52, height: 52)
                            .background(Color.dsBorder.opacity(0.5), in: Circle())
                    }
                    .buttonStyle(.plain)

                    // Play / Pause
                    Button {
                        togglePause()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(habit.accentColor, in: Circle())
                            .shadow(color: habit.accentColor.opacity(0.4),
                                    radius: 12, y: 4)
                            .offset(x: isPaused ? 2 : 0)
                    }
                    .buttonStyle(.plain)

                    // Skip
                    Button {
                        endSession(completed: true)
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.dsLabel)
                            .frame(width: 52, height: 52)
                            .background(Color.dsBorder.opacity(0.5), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Locked feedback
    
    private func triggerLockedFeedback() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
        
        withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
            shakeOffset = 12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                shakeOffset = -12
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                shakeOffset = 0
            }
        }
        
        withAnimation { showLockedMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showLockedMessage = false }
        }
    }
    
    // MARK: - Session logic
    
    private func startSession() {
        if let existing = existingSession {
            session = existing
            isPaused = false
            startTimer()
            hasStarted = true
            // Resume Live Activity
            LiveActivityManager.shared.update(
                habit: habit,
                session: existing,
                isPaused: false
            )
        } else {
            let s = FocusSession(habit: habit, durationSeconds: totalSeconds)
            context.insert(s)
            session = s
            startTimer()
            // Start Live Activity
            LiveActivityManager.shared.startActivity(habit: habit, session: s)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard !self.isPaused,
                      let s = self.session,
                      !s.isCompleted else { return }
                s.elapsedSeconds += 1

                if s.elapsedSeconds % 5 == 0 {
                    LiveActivityManager.shared.update(
                        habit: self.habit,
                        session: s,
                        isPaused: false
                    )
                }

                if s.elapsedSeconds >= s.durationSeconds {
                    self.timerCompleted()
                }
            }
        }
    }
    
    private func togglePause() {
        isPaused.toggle()
        pulseRing = !isPaused
        if isPaused {
            timer?.invalidate()
            timer = nil
            if let s = session {
                LiveActivityManager.shared.update(
                    habit: habit, session: s, isPaused: true
                )
            }
        } else {
            startTimer()
            if let s = session {
                LiveActivityManager.shared.update(
                    habit: habit, session: s, isPaused: false
                )
            }
        }
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        guard let s = session else { return }
        s.markCompleted()
        if !habit.isCompletedToday { habit.toggleToday() }
        if isDeep { endGuidedAccess() }
        LiveActivityManager.shared.endActivity()    // ← end Live Activity
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
    
    private func endSession(completed: Bool) {
        timer?.invalidate()
        timer = nil
        if completed, let s = session {
            s.markCompleted()
            if !habit.isCompletedToday { habit.toggleToday() }
        } else if let s = session, !completed {
            context.delete(s)
        }
        LiveActivityManager.shared.endActivity()    // ← end Live Activity
        if isDeep { endGuidedAccess() }
        dismiss()
    }
    
    private func pauseAndExit() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        if let s = session {
            LiveActivityManager.shared.update(
                habit: habit, session: s, isPaused: true
            )
        }
        if isDeep { endGuidedAccess() }
        dismiss()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
