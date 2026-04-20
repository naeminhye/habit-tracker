//
//  DesignSystem.swift
//  HabitTracker
//
//  Created by JaceyNguyen on 20/04/2026.
//

import SwiftUI

// MARK: - Color tokens

extension Color {

    static var dsIndigo: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "9B97F0") : UIColor(hex: "2D2A5E") })
    }

    static var dsCoral: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "FF8066") : UIColor(hex: "FF6B4A") })
    }

    static var dsMint: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "00E5AC") : UIColor(hex: "00C896") })
    }

    static var dsGold: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "FFC96B") : UIColor(hex: "FFB547") })
    }

    static var dsSurface: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "1C1B2E") : UIColor(hex: "F5F4F0") })
    }

    static var dsBackground: Color { Color(UIColor.systemBackground) }

    static var dsLabel: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "6E6D80") : UIColor(hex: "8B8A99") })
    }

    static var dsBorder: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: "2E2D45") : UIColor(hex: "E8E6F0") })
    }

    static let dsDark    = Color(hex: "0F0E1A")
    static var dsPrimaryText: Color { Color(UIColor.label) }

    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double(v         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        let r = CGFloat((v >> 16) & 0xFF) / 255
        let g = CGFloat((v >> 8)  & 0xFF) / 255
        let b = CGFloat(v         & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Typography

struct DSFont {
    // Hero numbers — streaks, big stats
    static func hero(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    // Section titles
    static func title(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold)
    }
    // All-caps labels
    static func capsLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium)
    }
    // Body
    static func body(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular)
    }
    // Bold body
    static func bodyBold(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .semibold)
    }
    // Caption
    static func caption(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular)
    }
}

// MARK: - Spacing

enum DSSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 14
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 28
    static let xxl: CGFloat = 40
}

// MARK: - Corner radius

enum DSRadius {
    static let sm:  CGFloat = 10
    static let md:  CGFloat = 14
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Card styles

struct DSCard: ViewModifier {
    var padding: CGFloat = DSSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dsSurface, in: RoundedRectangle(cornerRadius: DSRadius.md))
    }
}

struct DSCardBordered: ViewModifier {
    var color: Color = .dsBorder

    func body(content: Content) -> some View {
        content
            .background(Color.dsSurface, in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(color, lineWidth: 1)
            )
    }
}

extension View {
    func dsCard(padding: CGFloat = DSSpacing.md) -> some View {
        modifier(DSCard(padding: padding))
    }

    func dsCardBordered(color: Color = .dsBorder) -> some View {
        modifier(DSCardBordered(color: color))
    }
}

// MARK: - Section header

struct DSSectionHeader: View {
    let title: String
    var count: Int? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(DSFont.capsLabel())
                .foregroundStyle(Color.dsLabel)
                .kerning(0.8)

            if let count {
                Text("\(count)")
                    .font(DSFont.caption())
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.dsIndigo.opacity(0.08), in: Capsule())
                    .foregroundStyle(Color.dsIndigo)
            }

            Spacer()

            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DSFont.caption())
                        .foregroundStyle(Color.dsAccent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Stat badge

struct DSStatBadge: View {
    let value: String
    let label: String
    var color: Color = .dsIndigo
    var icon: String? = nil

    var body: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(DSFont.caption())
                        .foregroundStyle(color)
                }
                Text(value)
                    .font(DSFont.hero(22))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(DSFont.capsLabel(10))
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Progress bar

struct DSProgressBar: View {
    let value: Double          // 0–1
    var color: Color = .dsCoral
    var height: CGFloat = 4
    var showLabel: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.dsBorder)
                    .frame(height: height)
                Capsule()
                    .fill(value >= 1 ? ThemeManager.shared.accentColor : color)
                    .frame(width: max(0, geo.size.width * value), height: height)
                    .animation(.spring(response: 0.5), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - CTA Button

struct DSButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .dsCoral
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .kerning(0.5)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, fullWidth ? 0 : 28)
            .background(color, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pill tag

struct DSPill: View {
    let text: String
    var color: Color = .dsCoral
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(DSFont.caption())
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                filled ? color : color.opacity(0.1),
                in: Capsule()
            )
            .foregroundStyle(filled ? .white : color)
    }
}

// MARK: - Divider

struct DSDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dsBorder)
            .frame(height: 1)
    }
}

// MARK: - Avatar circle (for habit emoji)

struct DSHabitAvatar: View {
    let emoji: String
    let color: Color
    var size: CGFloat = 44
    var completed: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(completed ? color : color.opacity(0.12))
                .frame(width: size, height: size)

            if completed {
                Circle()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: size, height: size)
            }

            StickerText(
                text: emoji,
                fontSize: size * 0.48,
                outlineWidth: completed ? 1.5 : 0
            )
        }
    }
}

// MARK: - Streak badge

struct DSStreakBadge: View {
    let streak: Int
    var large: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: large ? 16 : 12))
            Text("\(streak)")
                .font(large ? DSFont.bodyBold(16) : DSFont.bodyBold(12))
                .foregroundStyle(Color.dsGold)
        }
        .padding(.horizontal, large ? 10 : 7)
        .padding(.vertical, large ? 5 : 3)
        .background(Color.dsGold.opacity(0.1), in: Capsule())
    }
}

// MARK: - Level badge

struct DSLevelBadge: View {
    let level: Int

    var body: some View {
        Text("LVL \(level)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.dsAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .strokeBorder(Color.dsAccent, lineWidth: 1.5)
            )
    }
}

// MARK: - Theme accent helper

extension Color {
    static var dsAccent: Color {
        ThemeManager.shared.accentColor
    }
}
