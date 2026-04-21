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
    @State private var outlineEffectEnabled = true

    private var savedDecoration: String? {
        let d = habit.decoration(for: date)
        return d?.isEmpty == false ? d : nil
    }

    private var previewDecoration: String? {
        pendingDecoration ?? savedDecoration
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "DDDDDA"))
                .frame(width: 32, height: 3)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Header
            HStack {
                Text("Pick a decoration")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.dsPrimaryText)
                Spacer()
                // Preview chip
                if let deco = previewDecoration, !deco.isEmpty {
                    Text(deco)
                        .font(.system(size: 16))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            ThemeManager.shared.accentColor.opacity(0.1),
                            in: Capsule()
                        )
                }
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.bottom, DSSpacing.md)

            DSDivider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DSSpacing.md) {
                    // Emoji grid
                    quickEmojiGrid
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.top, DSSpacing.md)

                    // iOS 17 outline toggle
                    HStack {
                        Text("White outline effect")
                            .font(DSFont.secondary())
                            .foregroundStyle(Color.dsPrimaryText)
                        Spacer()
                        Toggle("", isOn: $outlineEffectEnabled)
                            .tint(ThemeManager.shared.accentColor)
                            .labelsHidden()
                            .frame(width: 44, height: 24)
                    }
                    .padding(.horizontal, DSSpacing.lg)

                    // Browse device stickers
                    Button {
                        showingStickerPicker = true
                    } label: {
                        Text("Browse device stickers")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dsPrimaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.dsCardBackground,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DSSpacing.lg)

                    // Apply button
                    Button {
                        applyAndDismiss()
                    } label: {
                        Text("Apply decoration")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                pendingDecoration != nil
                                    ? ThemeManager.shared.accentColor
                                    : Color.dsBorder,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(pendingDecoration == nil)
                    .padding(.horizontal, DSSpacing.lg)

                    // Skip link
                    Button {
                        onDismiss?()
                        dismiss()
                    } label: {
                        Text("Mark complete without decoration")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, DSSpacing.lg)
                }
            }
        }
        .background(Color.dsPageBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingStickerPicker) {
            StickerPickerSheet(
                selectedEmoji: Binding(
                    get: { pendingDecoration ?? "" },
                    set: { emoji in
                        if !emoji.isEmpty { pendingDecoration = emoji }
                    }
                ),
                selectedSticker: Binding(
                    get: { nil },
                    set: { img in
                        guard let img, let data = img.pngData() else { return }
                        pendingDecoration = "sticker:" + data.base64EncodedString()
                    }
                )
            )
        }
    }

    // MARK: - Emoji grid (5 columns per spec)

    private var quickEmojiGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
            spacing: 8
        ) {
            ForEach(quickEmojis, id: \.self) { emoji in
                Button {
                    withAnimation(.easeOut(duration: 0.1)) {
                        pendingDecoration = pendingDecoration == emoji
                            ? nil : emoji
                    }
                } label: {
                    Group {
                        if outlineEffectEnabled {
                            StickerText(text: emoji,
                                        fontSize: 28,
                                        outlineWidth: 2)
                        } else {
                            Text(emoji)
                                .font(.system(size: 28))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Color(hex: "F5F5F3"),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                pendingDecoration == emoji
                                    ? Color.dsPrimaryText
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .scaleEffect(pendingDecoration == emoji ? 1.1 : 1.0)
                    .animation(.easeOut(duration: 0.1),
                               value: pendingDecoration)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Apply

    private func applyAndDismiss() {
        if let pending = pendingDecoration {
            habit.setDecoration(pending, for: date)
        }
        onDismiss?()
        dismiss()
    }

    let quickEmojis: [String] = [
        "⭐️","🔥","💪","✅","🎯","🏆","💯","🌟",
        "✨","🎉","🥳","💥","🚀","❤️","🩷","🧡",
        "💛","💚","💙","💜","🌈","☀️","🌊","🌸",
        "🍀","🦋","🐝","🎈","🎁","🍭","😊","😎",
        "🤩","🥰","👏","🙌","🫶","💫","🌙","⚡️",
    ]
}
