//
//  MilestoneBannerView.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI

struct MilestoneBannerView: View {
    let unlock: MilestoneUnlock
    var onDismiss: () -> Void

    @State private var offset: CGFloat = -120
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 14) {
            // Badge emoji with glow ring
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                StickerText(
                    text: unlock.badge?.emoji ?? unlock.milestone.emoji,
                    fontSize: 28,
                    outlineWidth: 2
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Milestone reached!")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(unlock.milestone.title)
                    .font(.subheadline.bold())
                if let badge = unlock.badge {
                    Text("🏅 \(badge.name) badge unlocked")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color.secondary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
            // Auto-dismiss after 3 seconds
//            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//                dismiss()
//            }
            // Change 4 seconds to 3 seconds per spec
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {   // ← was 4
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            offset = -120
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - View modifier for easy attachment

struct MilestoneOverlayModifier: ViewModifier {
    @Binding var unlocks: [MilestoneUnlock]

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let first = unlocks.first {
                MilestoneBannerView(unlock: first) {
                    if !unlocks.isEmpty { unlocks.removeFirst() }
                }
                .zIndex(999)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func milestoneOverlay(unlocks: Binding<[MilestoneUnlock]>) -> some View {
        modifier(MilestoneOverlayModifier(unlocks: unlocks))
    }
}
