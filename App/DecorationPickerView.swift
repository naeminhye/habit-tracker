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

    @State private var pendingDecoration: String? = nil
    @State private var showingStickerPicker = false

    // The decoration currently saved for this date
    private var savedDecoration: String? {
        let d = habit.decoration(for: date)
        return d?.isEmpty == false ? d : nil
    }

    // What to show in preview — pending takes priority
    private var previewDecoration: String? {
        pendingDecoration ?? savedDecoration
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                habitRowPreview
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.top, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.md)

                DSDivider()

                browseButton
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.top, DSSpacing.md)
                    .padding(.bottom, DSSpacing.sm)

                quickEmojiGrid

                Spacer(minLength: 0)
            }
            .navigationTitle("Decorate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundStyle(Color.dsLabel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let pending = pendingDecoration {
                            habit.setDecoration(pending, for: date)
                        }
                        onDismiss?()
                        dismiss()
                    }
                    .font(DSFont.bodyBold())
                    .foregroundStyle(
                        pendingDecoration != nil
                            ? ThemeManager.shared.accentColor
                            : Color.dsLabel
                    )
                    .disabled(pendingDecoration == nil && savedDecoration == nil)
                }
            }
            .sheet(isPresented: $showingStickerPicker) {
                StickerPickerSheet(
                    selectedEmoji: Binding(
                        get: { pendingDecoration ?? "" },
                        set: { emoji in
                            if !emoji.isEmpty {
                                pendingDecoration = emoji
                            }
                        }
                    ),
                    selectedSticker: Binding(
                        get: { nil },
                        set: { img in
                            guard let img,
                                  let data = img.pngData() else { return }
                            pendingDecoration = "sticker:" + data.base64EncodedString()
                        }
                    )
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Habit row preview (mirrors HabitRowView exactly)

    private var habitRowPreview: some View {
        HStack(spacing: DSSpacing.md) {
            // Avatar — same as HabitRowView
            ZStack(alignment: .bottomTrailing) {
                DSHabitAvatar(
                    emoji: habit.emoji,
                    color: ThemeManager.shared.accentColor,
                    size: 48,
                    completed: true
                )

                // Decoration badge — StickerText
                if let deco = previewDecoration, !deco.isEmpty {
                    UniversalSticker(value: deco, fontSize: 16, outlineWidth: 1.5)
                        .offset(x: 6, y: 6)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(DSFont.bodyBold())
                    .foregroundStyle(Color.dsLabel)
                    .strikethrough(true, color: Color.dsLabel)

                if previewDecoration != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(ThemeManager.shared.accentColor)
                        Text("Decorated!")
                            .font(DSFont.caption())
                            .foregroundStyle(ThemeManager.shared.accentColor)
                    }
                } else {
                    Text("Tap an emoji to preview")
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsLabel)
                }
            }

            Spacer()

            DSPill(text: habit.frequencyLabel, color: Color.dsIndigo)
        }
        .padding(DSSpacing.md)
        .background(ThemeManager.shared.accentColor.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .strokeBorder(ThemeManager.shared.accentColor.opacity(0.25), lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: previewDecoration)
    }

    // MARK: - Browse button

    private var browseButton: some View {
        Button {
            showingStickerPicker = true
        } label: {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                Text("Browse Stickers & Emoji")
                    .font(DSFont.bodyBold())
            }
            .foregroundStyle(Color.dsIndigo)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Color.dsIndigo.opacity(0.06),
                in: RoundedRectangle(cornerRadius: DSRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsIndigo.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick emoji grid

    private var quickEmojiGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 6),
                spacing: DSSpacing.sm
            ) {
                // Clear button
                Button {
                    pendingDecoration = nil
                    habit.setDecoration(nil, for: date)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: DSRadius.sm)
                            .fill(Color.dsBorder.opacity(0.4))
                            .aspectRatio(1, contentMode: .fit)
                        Text("skip")
                            .font(DSFont.caption(10))
                            .foregroundStyle(Color.dsLabel)
                    }
                }
                .buttonStyle(.plain)

                ForEach(quickEmojis, id: \.self) { emoji in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            pendingDecoration = emoji
                        }
                    } label: {
                        StickerText(text: emoji, fontSize: 30, outlineWidth: 2)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(
                                pendingDecoration == emoji
                                    ? ThemeManager.shared.accentColor.opacity(0.12)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: DSRadius.sm)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.sm)
                                    .strokeBorder(
                                        pendingDecoration == emoji
                                            ? ThemeManager.shared.accentColor.opacity(0.4)
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DSSpacing.md)
        }
    }

    let quickEmojis: [String] = [
        "⭐️","🔥","💪","✅","🎯","🏆","💯","🌟",
        "✨","🎉","🥳","💥","🚀","❤️","🩷","🧡",
        "💛","💚","💙","💜","🌈","☀️","🌊","🌸",
        "🍀","🦋","🐝","🎈","🎁","🍭","😊","😎",
        "🤩","🥰","👏","🙌","🫶","💫","🌙","⚡️",
    ]
}
