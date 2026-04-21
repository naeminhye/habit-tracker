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
        ("Teal",     "4A9E8A"),
        ("Coral",    "CC6B5A"),
        ("Orange",   "B87840"),
        ("Mint",     "3E9E70"),
        ("Blue",     "4A7ECC"),
        ("Indigo",   "6A5ECC"),
        ("Purple",   "8A4ECC"),
        ("Pink",     "CC4A7A"),
        ("Green",    "3A9E7A"),
        ("Yellow",   "8C8A30"),
        ("Brown",    "7A6050"),
        ("Graphite", "7A7A72"),
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
                            .fill(Color(item.hex))
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
