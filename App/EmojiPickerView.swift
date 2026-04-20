//
//  EmojiPickerView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    let categories: [(name: String, emojis: [String])] = [
        ("Fitness", ["🏃","🚴","🏊","🧘","💪","🤸","🏋️","⛹️","🤾","🧗","🏄","🤺","🥊","🎽","👟","🏅"]),
        ("Health",  ["💧","🥗","🥦","🍎","🧃","💊","🩺","🫀","🫁","🧬","😴","🛁","🪥","🧘","🌿","🍵"]),
        ("Mind",    ["📚","✍️","🧠","🎯","💡","🔬","🎓","📝","🗒️","🧩","♟️","🎲","🔭","🎨","🖊️","📖"]),
        ("Creative",["🎸","🎹","🎺","🎻","🥁","🎤","🎬","🖌️","✏️","📷","🎭","🎪","🎠","🎡","🪄","🎶"]),
        ("Nature",  ["🌅","🌿","🌱","🌳","🌸","🌻","🍃","🌊","🏔️","🌙","⭐️","☀️","🌈","❄️","🔥","⚡️"]),
        ("Life",    ["🏠","🚗","✈️","🗺️","💰","📱","💻","⌚️","🎁","🛒","👔","🧹","🍳","☕️","🐶","❤️"]),
        ("Symbols", ["✅","⭐️","🏆","🎯","💯","🔑","🗝️","💎","🪙","📌","🔔","⚡️","💫","🌟","✨","🎊"]),
    ]

    @State private var searchText = ""
    @State private var selectedCategory = 0

    var filteredEmojis: [String] {
        if searchText.isEmpty {
            return categories[selectedCategory].emojis
        }
        return categories.flatMap(\.emojis).filter { emoji in
            emoji.unicodeScalars.first.map { $0.value > 127 } ?? false
        }
    }

    var searchResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return categories.flatMap(\.emojis)
    }

    var displayEmojis: [String] {
        searchText.isEmpty ? categories[selectedCategory].emojis : searchResults
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search categories…", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Category pills
                if searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories.indices, id: \.self) { i in
                                Button {
                                    selectedCategory = i
                                } label: {
                                    Text(categories[i].name)
                                        .font(.subheadline)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(
                                            selectedCategory == i
                                                ? Color.accentColor
                                                : Color.secondary.opacity(0.15),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(
                                            selectedCategory == i ? .white : .primary
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }

                Divider()

                // Emoji grid
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: 4
                    ) {
                        ForEach(displayEmojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 36))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .background(
                                        selectedEmoji == emoji
                                            ? Color.accentColor.opacity(0.2)
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
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
