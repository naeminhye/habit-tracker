//
//  TagBadge.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct TagBadge: View {
    let tag: Tag
    var small: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(tag.color)
                .frame(width: small ? 5 : 6, height: small ? 5 : 6)
            Text(tag.label)
                .font(small ? .system(size: 10) : .caption)
                .fontWeight(.medium)
                .foregroundStyle(tag.color)
        }
        .padding(.horizontal, small ? 6 : 8)
        .padding(.vertical, small ? 2 : 3)
        .background(
            tag.color.opacity(0.12),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .strokeBorder(tag.color.opacity(0.25), lineWidth: 0.5)
        )
    }
}
