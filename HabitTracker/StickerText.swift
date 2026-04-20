//
//  StickerText.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct StickerText: View {
    let text: String
    let fontSize: CGFloat
    var outlineWidth: CGFloat = 3

    var body: some View {
        if #available(iOS 17.0, *) {
            Text(text)
                .font(.system(size: fontSize))
                .outlineEffect(width: outlineWidth)
        } else {
            legacySticker
        }
    }

    // Fallback for older iOS
    private var legacySticker: some View {
        Canvas { ctx, size in
            let steps = 16
            for i in 0..<steps {
                let angle = (Double(i) / Double(steps)) * 2 * .pi
                let dx = cos(angle) * outlineWidth
                let dy = sin(angle) * outlineWidth
                let resolved = ctx.resolve(
                    Text(text).font(.system(size: fontSize))
                )
                ctx.draw(
                    resolved,
                    at: CGPoint(
                        x: size.width / 2 + dx,
                        y: size.height / 2 + dy
                    ),
                    anchor: .center
                )
            }
            let resolved = ctx.resolve(
                Text(text).font(.system(size: fontSize))
            )
            ctx.draw(
                resolved,
                at: CGPoint(x: size.width / 2, y: size.height / 2),
                anchor: .center
            )
        }
        .frame(
            width: fontSize + outlineWidth * 4,
            height: fontSize + outlineWidth * 4
        )
    }
}

// MARK: - iOS 17 outline modifier

@available(iOS 17.0, *)
private struct OutlineEffect: ViewModifier {
    let width: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                // Use compositingGroup + shadow trick for clean outline
                content
                    .foregroundStyle(.white)
                    .colorMultiply(.white)
                    .blur(radius: width * 0.6)
                    .brightness(1)
                    .scaleEffect((width + getFontSize()) / getFontSize())
            }
    }

    private func getFontSize() -> CGFloat { 1 }
}

@available(iOS 17.0, *)
extension View {
    func outlineEffect(width: CGFloat) -> some View {
        modifier(StickerOutlineModifier(width: width))
    }
}

@available(iOS 17.0, *)
struct StickerOutlineModifier: ViewModifier {
    let width: CGFloat

    func body(content: Content) -> some View {
        ZStack {
            // White outline layer — rendered at slightly larger scale
            content
                .saturation(0)
                .brightness(10)
                .scaleEffect(1 + (width / 20))
                .blur(radius: width * 0.35)

            // Real emoji on top
            content
        }
        .compositingGroup()
    }
}

// MARK: - Universal sticker renderer (emoji or image)

struct UniversalSticker: View {
    let value: String          // emoji string OR "sticker:base64..."
    let fontSize: CGFloat
    var outlineWidth: CGFloat = 2

    private var isImageSticker: Bool { value.hasPrefix("sticker:") }

    private var stickerImage: UIImage? {
        guard isImageSticker else { return nil }
        let b64 = String(value.dropFirst("sticker:".count))
        guard let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        if isImageSticker, let img = stickerImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: fontSize, height: fontSize)
        } else {
            StickerText(text: value, fontSize: fontSize, outlineWidth: outlineWidth)
        }
    }
}
