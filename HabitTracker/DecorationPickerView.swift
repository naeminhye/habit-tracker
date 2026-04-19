//
//  DecorationPickerView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct DecorationPickerView: View {
    let date: Date
    @Bindable var habit: Habit
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    let decorations: [String] = [
        "⭐️","🔥","💪","✅","🎯","🏆","💯","🌟",
        "✨","🎉","🥳","💥","🚀","❤️","🩷","🧡",
        "💛","💚","💙","💜","🤍","🖤","🌈","☀️",
        "🌊","🌸","🍀","🦋","🐝","🎈","🎁","🍭",
        "😊","😎","🤩","🥰","😴","🤔","👏","🙌",
    ]

    var currentDecoration: String? { habit.decoration(for: date) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview cell
                VStack(spacing: 8) {
                    // Preview of the Emoji
                    
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(habit.accentColor.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Text(habit.emoji)
                            .font(.system(size: 36))
                        Text(currentDecoration ?? "")
                            .font(.system(size: 14))
                            .padding(2)
                            .offset(x: 14, y: 14)
                    }
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Tap to decorate this day")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 16)

                Divider()

                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 10
                    ) {
                        // Skip / clear
                        Button {
                            habit.setDecoration(nil, for: date)
                            onDismiss?()
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                                    .aspectRatio(1, contentMode: .fit)
                                Text("skip")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(decorations, id: \.self) { emoji in
                            Button {
                                habit.setDecoration(emoji, for: date)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .background(
                                        currentDecoration == emoji
                                            ? habit.accentColor.opacity(0.2)
                                            : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("How did it feel?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        habit.setDecoration(nil, for: date)
                        onDismiss?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
