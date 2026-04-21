//
//  CompletionToastView.swift
//  HabitTracker
//
//  Created by BangChitty on 21/04/2026.
//

import SwiftUI

struct CompletionToast: Identifiable {
    let id = UUID()
    let habitName: String
    let habitEmoji: String
    let accentColor: Color
    let streak: Int
    let message: String

    static func make(for habit: Habit) -> CompletionToast {
        CompletionToast(
            habitName: habit.name,
            habitEmoji: habit.emoji,
            accentColor: habit.accentColor,
            streak: habit.currentStreak,
            message: motivationalMessage(streak: habit.currentStreak)
        )
    }

    static func motivationalMessage(streak: Int) -> String {
        switch streak {
        case 1:      return "Great start! 🌱"
        case 2:      return "Two in a row!"
        case 3:      return "Three days strong!"
        case 4...6:  return "Keep it going!"
        case 7:      return "One week streak! 🔥"
        case 8...13: return "On fire! \(streak) days!"
        case 14:     return "Two weeks! 💪"
        case 15...29: return "\(streak) day streak!"
        case 30:     return "One month! Legendary! 🏆"
        default:     return "\(streak) days and counting!"
        }
    }
}

struct CompletionToastView: View {
    let toast: CompletionToast
    var onDismiss: () -> Void

    @State private var offset: CGFloat = 80
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.9

    var body: some View {
        HStack(spacing: 12) {
            // Emoji with bounce
            ZStack {
                Circle()
                    .fill(toast.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(toast.habitEmoji)
                    .font(.system(size: 20))
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.habitName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                    .lineLimit(1)
                Text(toast.message)
                    .font(.system(size: 11))
                    .foregroundStyle(toast.accentColor)
            }

            Spacer()

            // Checkmark
            ZStack {
                Circle()
                    .fill(toast.accentColor)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color.dsCardBackground,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(toast.accentColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .offset(y: offset)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            // Slide up
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
                scale = 1
            }
            // Haptic
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            // Auto dismiss after 2.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
        .onTapGesture { dismiss() }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            offset = 80
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Toast queue modifier

struct ToastQueueModifier: ViewModifier {
    @Binding var toasts: [CompletionToast]

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let toast = toasts.first {
                CompletionToastView(toast: toast) {
                    if !toasts.isEmpty { toasts.removeFirst() }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)    // above tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(998)
                .id(toast.id)
            }
        }
        .animation(.spring(response: 0.4), value: toasts.isEmpty)
    }
}

extension View {
    func completionToasts(_ toasts: Binding<[CompletionToast]>) -> some View {
        modifier(ToastQueueModifier(toasts: toasts))
    }
}
