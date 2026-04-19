//
//  HabitColorPicker.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct HabitColorPicker: View {
    @Binding var selectedHex: String

    let colors: [(name: String, hex: String)] = [
        ("Blue",    "007AFF"), ("Purple",  "AF52DE"), ("Pink",    "FF2D55"),
        ("Red",     "FF3B30"), ("Orange",  "FF9500"), ("Yellow",  "FFCC00"),
        ("Green",   "34C759"), ("Teal",    "5AC8FA"), ("Mint",    "00C7BE"),
        ("Indigo",  "5856D6"), ("Brown",   "A2845E"), ("Gray",    "8E8E93"),
    ]

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 6),
            spacing: 10
        ) {
            ForEach(colors, id: \.hex) { item in
                let isSelected = selectedHex.uppercased() == item.hex.uppercased()
                Button {
                    selectedHex = item.hex
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: item.hex))
                            .frame(width: 40, height: 40)
                        if isSelected {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2.5)
                                .frame(width: 40, height: 40)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.name)
            }
        }
        .padding(.vertical, 4)
    }
}
