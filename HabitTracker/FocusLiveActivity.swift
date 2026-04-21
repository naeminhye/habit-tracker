//
//  FocusLiveActivity.swift
//  HabitTracker
//
//  Created by BangChitty on 21/04/2026.
//

import ActivityKit
import SwiftUI

// MARK: - Attributes

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var habitName: String
        var habitEmoji: String
        var elapsedSeconds: Int
        var durationSeconds: Int
        var isPaused: Bool
        var accentColorHex: String

        var progress: Double {
            guard durationSeconds > 0 else { return 0 }
            return min(Double(elapsedSeconds) / Double(durationSeconds), 1.0)
        }

        var remainingSeconds: Int {
            max(durationSeconds - elapsedSeconds, 0)
        }

        var formattedRemaining: String {
            let m = remainingSeconds / 60
            let s = remainingSeconds % 60
            return String(format: "%02d:%02d", m, s)
        }
    }

    var habitID: String
}

// MARK: - Live Activity Views

struct FocusLiveActivityView: View {
    let state: FocusActivityAttributes.ContentState

    var accentColor: Color {
        Color(state.accentColorHex)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Emoji
            Text(state.habitEmoji)
                .font(.system(size: 24))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(state.habitName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.isPaused ? "Paused" : "Focusing…")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Timer ring + time
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(accentColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40, height: 40)
                Text(state.formattedRemaining)
                    .font(.system(size: 9, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Dynamic Island compact

struct FocusDynamicIslandCompact: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 4) {
            Text(state.habitEmoji)
                .font(.system(size: 14))
            Text(state.formattedRemaining)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color(state.accentColorHex))
        }
    }
}

// MARK: - Dynamic Island minimal

struct FocusDynamicIslandMinimal: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: state.progress)
                .stroke(Color(state.accentColorHex),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 20, height: 20)
            Text(state.habitEmoji)
                .font(.system(size: 10))
        }
    }
}

// MARK: - Dynamic Island expanded

struct FocusDynamicIslandExpanded: View {
    let state: FocusActivityAttributes.ContentState

    var accentColor: Color { Color(state.accentColorHex) }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(state.habitEmoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 3) {
                    Text(state.habitName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text(state.isPaused ? "Paused" : "Focus session in progress")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                // Big timer
                Text(state.formattedRemaining)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 4)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geo.size.width * state.progress,
                               height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
