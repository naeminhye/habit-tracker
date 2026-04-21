//
//  AppIconGenerator.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import UIKit

struct AppIconView: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("7F77DD"),
                            Color("534AB7")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Inner ring
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: size * 0.04)
                .frame(width: size * 0.62, height: size * 0.62)

            // Progress arc
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: size * 0.06,
                        lineCap: .round
                    )
                )
                .frame(width: size * 0.62, height: size * 0.62)
                .rotationEffect(.degrees(-90))

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

enum AppIconGenerator {
    @MainActor
    static func generate() {
        let sizes: [(CGFloat, String)] = [
            (1024, "icon_1024"),
            (180,  "icon_60_3x"),
            (120,  "icon_60_2x"),
            (167,  "icon_83.5_2x"),
            (152,  "icon_76_2x"),
            (80,   "icon_40_2x"),
            (120,  "icon_40_3x"),
            (58,   "icon_29_2x"),
            (87,   "icon_29_3x"),
        ]

        for (size, name) in sizes {
            let view = AppIconView(size: size)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            if let img = renderer.uiImage,
               let data = img.pngData() {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(name).png")
                try? data.write(to: url)
                print("Saved: \(url.path)")
            }
        }
    }
}
