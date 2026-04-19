//
//  StickerText.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import UIKit

struct StickerText: View {
    let text: String
    let fontSize: CGFloat
    var outlineWidth: CGFloat = 3

    var body: some View {
        Canvas { ctx, size in
            // Draw white outline by stamping the emoji at offsets
            let steps = 12
            for i in 0..<steps {
                let angle = (Double(i) / Double(steps)) * 2 * .pi
                let dx = cos(angle) * outlineWidth
                let dy = sin(angle) * outlineWidth

                var whiteText = AttributedString(text)
                whiteText.font = .systemFont(ofSize: fontSize)
                whiteText.foregroundColor = .white

                // Resolve and draw offset copy
                let resolved = ctx.resolve(
                    Text(AttributedString(text))
                        .font(.system(size: fontSize))
                )
                ctx.draw(
                    resolved,
                    at: CGPoint(x: size.width / 2 + dx, y: size.height / 2 + dy),
                    anchor: .center
                )
            }

            // Draw real emoji centered on top
            let resolved = ctx.resolve(
                Text(text).font(.system(size: fontSize))
            )
            ctx.draw(resolved, at: CGPoint(x: size.width / 2, y: size.height / 2), anchor: .center)
        }
        .frame(width: fontSize + outlineWidth * 4,
               height: fontSize + outlineWidth * 4)
    }
}
