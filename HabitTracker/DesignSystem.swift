//
//  DesignSystem.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI
import UIKit

// MARK: - Color tokens (exact from DS)

extension Color {

    // MARK: Surfaces
    static var htBg: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.17, c: 0.004, h: 90)
                : UIColor(oklch: 0.97, c: 0.004, h: 90)
        })
    }

    static var htSurface: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.22, c: 0.005, h: 90)
                : UIColor(oklch: 1.0,  c: 0.0,   h: 0)
        })
    }

    static var htSurfaceAlt: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.20, c: 0.004, h: 90)
                : UIColor(oklch: 0.965, c: 0.005, h: 90)
        })
    }

    static var htBorderC: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.32, c: 0.004, h: 90)
                : UIColor(oklch: 0.90, c: 0.004, h: 90)
        })
    }

    // MARK: Foreground
    static var htFg: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.92, c: 0.005, h: 90)
                : UIColor(oklch: 0.22, c: 0.005, h: 90)
        })
    }

    static var htFgSecondary: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.65, c: 0.01, h: 90)
                : UIColor(oklch: 0.56, c: 0.01, h: 90)
        })
    }

    static var htFgTertiary: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(oklch: 0.50, c: 0.01, h: 90)
                : UIColor(oklch: 0.72, c: 0.01, h: 90)
        })
    }

    // MARK: Tint (dynamic — follows ThemeManager hue)
    static var htTint: Color { ThemeManager.shared.accentColor }
    static var htTintSoft: Color { ThemeManager.shared.accentColor.opacity(0.12) }
    static var htTintSofter: Color { ThemeManager.shared.accentColor.opacity(0.06) }
    static var htTintDeep: Color { ThemeManager.shared.accentColor.opacity(0.7) }

    // MARK: Status — done
    static let htDoneBg  = Color(UIColor(oklch: 0.95, c: 0.04,  h: 135))
    static let htDoneFg  = Color(UIColor(oklch: 0.38, c: 0.09,  h: 140))

    // MARK: Status — pending
    static let htPendingBg = Color(UIColor(oklch: 0.97, c: 0.004, h: 90))
    static let htPendingFg = Color(UIColor(oklch: 0.56, c: 0.01,  h: 90))

    // MARK: Status — partial
    static let htPartialBg = Color(UIColor(oklch: 0.95, c: 0.04, h: 75))
    static let htPartialFg = Color(UIColor(oklch: 0.48, c: 0.09, h: 60))

    // MARK: Status — missed
    static let htMissedBg = Color(UIColor(oklch: 0.95, c: 0.03, h: 25))
    static let htMissedFg = Color(UIColor(oklch: 0.50, c: 0.12, h: 25))

    // MARK: Heatmap
    static let htHm0    = Color(UIColor(oklch: 0.97, c: 0.004, h: 90))
    static let htHm1    = Color(UIColor(oklch: 0.88, c: 0.07,  h: 150))
    static let htHm2    = Color(UIColor(oklch: 0.68, c: 0.13,  h: 150))
    static let htHm3    = Color(UIColor(oklch: 0.48, c: 0.13,  h: 150))
    static let htHmMiss = Color(UIColor(oklch: 0.87, c: 0.06,  h: 25))

    // MARK: Semantic
    static let htFireBg = Color(UIColor(oklch: 0.95, c: 0.04, h: 75))
    static let htFireFg = Color(UIColor(oklch: 0.48, c: 0.09, h: 60))
    static let htIceBg  = Color(UIColor(oklch: 0.95, c: 0.03, h: 240))
    static let htIceFg  = Color(UIColor(oklch: 0.42, c: 0.09, h: 245))
    static let htGoldBg = Color(UIColor(oklch: 0.95, c: 0.04, h: 80))
    static let htGoldFg = Color(UIColor(oklch: 0.55, c: 0.09, h: 70))

    // MARK: Backwards compat aliases
    static var dsSurface: Color    { htBg }
    static var dsBackground: Color { htSurface }
    static var dsPageBackground: Color { htBg }
    static var dsCardBackground: Color { htSurface }
    static var dsBorder: Color     { htBorderC }
    static var dsPrimaryText: Color { htFg }
    static var dsLabel: Color      { htFgSecondary }
    static var dsHint: Color       { htFgTertiary }
    static var dsAccent: Color     { htTint }
    static var dsMint: Color       { htTint }
    static var dsGold: Color       { htGoldFg }
    static var dsIndigo: Color     { htFg }

    // MARK: Hex init (kept for habit accent colors)
    init(hex: String) {
        let v = UInt64(hex.trimmingCharacters(in: .init(charactersIn: "#")),
                       radix: 16) ?? 0
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double(v         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - UIColor OKLCH helper

extension UIColor {
    /// Approximate oklch → sRGB conversion (good enough for UI tokens)
    convenience init(oklch l: Double, c: Double, h: Double) {
        // oklch → oklab
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)

        // oklab → linear sRGB (via XYZ D65)
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let lc = l_ * l_ * l_
        let mc = m_ * m_ * m_
        let sc = s_ * s_ * s_

        var r =  4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc
        var g = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc
        var bv = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc

        // gamma
        func gc(_ x: Double) -> Double {
            x >= 0.0031308 ? 1.055 * pow(x, 1/2.4) - 0.055 : 12.92 * x
        }
        r = max(0, min(1, gc(r)))
        g = max(0, min(1, gc(g)))
        bv = max(0, min(1, gc(bv)))

        self.init(red: CGFloat(r), green: CGFloat(g),
                  blue: CGFloat(bv), alpha: 1)
    }

    convenience init(hex: String) {
        let v = UInt64(hex.trimmingCharacters(in: .init(charactersIn: "#")),
                       radix: 16) ?? 0
        self.init(
            red:   CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8)  & 0xFF) / 255,
            blue:  CGFloat(v         & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Typography (SF Pro — spec says substitute SF Pro for Inter on iOS)

struct DSFont {
    static func displayL()   -> Font { .system(size: 28, weight: .medium) }
    static func displayM()   -> Font { .system(size: 22, weight: .medium) }
    static func title()      -> Font { .system(size: 16, weight: .medium) }
    static func body()       -> Font { .system(size: 15, weight: .regular) }
    static func bodyBold(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium)
    }
    static func secondary()  -> Font { .system(size: 13, weight: .regular) }
    static func tertiary()   -> Font { .system(size: 11, weight: .regular) }
    static func caption(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .regular)
    }
    static func overline()   -> Font {
        .system(size: 9, weight: .medium)
    }
    // Monospaced for timer/numbers
    static func mono(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Spacing (exact from DS)

enum DSSpacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s5: CGFloat = 16
    static let s6: CGFloat = 20
    static let s8: CGFloat = 32
    // Aliases
    static var xs:  CGFloat { s1 }
    static var sm:  CGFloat { s2 }
    static var md:  CGFloat { s3 }
    static var lg:  CGFloat { s5 }
    static var xl:  CGFloat { s6 }
    static var xxl: CGFloat { s8 }
}

// MARK: - Radii (exact from DS)

enum DSRadius {
    static let card:    CGFloat = 12
    static let chip:    CGFloat = 10
    static let button:  CGFloat = 10
    static let segment: CGFloat = 8
    static let input:   CGFloat = 8
    static let heatmap: CGFloat = 3
    static let progress: CGFloat = 3
    static let full:    CGFloat = 9999
    // Aliases
    static var sm:  CGFloat { segment }
    static var md:  CGFloat { card }
    static var lg:  CGFloat { card }
    static var pill: CGFloat { full }
}

// MARK: - Animation (exact from DS)

enum DSAnim {
    static let fast = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.12)
    static let base = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.18)
    static let slow = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.24)
}

// MARK: - Progress bar

struct DSProgressBar: View {
    let value: Double
    var color: Color = .htTint
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.htBorderC)
                    .frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * min(value, 1.0)),
                           height: height)
                    .animation(DSAnim.slow, value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Status chip

struct HTStatusChip: View {
    enum Status {
        case done
        case pending
        case partial(String)
        case missed
        case timer(String)
        case streak(Int)
        case ice(Int)
    }

    let status: Status

    var body: some View {
        HStack(spacing: 3) {
            switch status {
            case .done:
                Text("Done")
                    .foregroundStyle(Color.htDoneFg)
                    .background(Color.htDoneBg)
            case .pending:
                Text("Pending")
                    .foregroundStyle(Color.htPendingFg)
                    .background(Color.htPendingBg)
                    .overlay(Capsule().strokeBorder(Color.htBorderC, lineWidth: 0.5))
            case .partial(let s):
                Text(s)
                    .foregroundStyle(Color.htPartialFg)
                    .background(Color.htPartialBg)
            case .missed:
                Text("Missed")
                    .foregroundStyle(Color.htMissedFg)
                    .background(Color.htMissedBg)
            case .timer(let s):
                Text(s)
                    .foregroundStyle(Color.htPartialFg)
                    .background(Color.htPartialBg)
            case .streak(let n):
                Text("🔥 \(n)")
                    .foregroundStyle(Color.htFireFg)
                    .background(Color.htFireBg)
            case .ice(let n):
                Text("🧊 \(n)")
                    .foregroundStyle(Color.htIceFg)
                    .background(Color.htIceBg)
            }
        }
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .clipShape(Capsule())
    }
}

// MARK: - Filter chip

struct HTFilterChip: View {
    let label: String
    let isActive: Bool
    var dotColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let c = dotColor {
                    Circle().fill(c).frame(width: 5, height: 5)
                }
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .medium : .regular))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(height: 22)
            .background(
                isActive ? Color.htFg : Color.htSurfaceAlt,
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    isActive ? Color.clear : Color.htBorderC,
                    lineWidth: 0.5
                )
            )
            .foregroundStyle(isActive ? Color.htBg : Color.htFgSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section overline

struct HTOverline: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color.htFgSecondary)
            .kerning(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card container

struct HTCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, DSSpacing.s3)
            .padding(.vertical, DSSpacing.s3)
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
    }
}

// MARK: - Segmented control

struct HTSegmented<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let options: [T]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { opt in
                let isActive = selection == opt
                Button {
                    withAnimation(DSAnim.base) { selection = opt }
                } label: {
                    Text(opt.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(
                            isActive ? Color.htFg : Color.clear,
                            in: RoundedRectangle(cornerRadius: DSRadius.segment)
                        )
                        .foregroundStyle(isActive ? Color.htBg : Color.htFgSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.htSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: DSRadius.segment + 3))
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.segment + 3)
                .strokeBorder(Color.htBorderC, lineWidth: 0.5)
        )
    }
}

// MARK: - Primary button

struct HTPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .htTint
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 13)) }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                disabled ? color.opacity(0.5) : color,
                in: RoundedRectangle(cornerRadius: DSRadius.button)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - Secondary button

struct HTSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .htTint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 13)) }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.htSurface,
                        in: RoundedRectangle(cornerRadius: DSRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.button)
                    .strokeBorder(Color.htBorderC, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DSButton wrapper (keeps existing API)

struct DSButton: View {
    enum Style { case primary, secondary }

    let title: String
    var icon: String? = nil
    var color: Color = .htTint
    var style: Style = .primary
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(style == .primary ? .white : color)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 44)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(backgroundView)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if style == .primary {
            RoundedRectangle(cornerRadius: DSRadius.button).fill(color)
        } else {
            RoundedRectangle(cornerRadius: DSRadius.button)
                .fill(Color.htSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.button)
                        .strokeBorder(Color.htBorderC, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Stat tile

struct HTStatTile: View {
    let label: String
    let value: String
    var color: Color = .htFg

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.htFgTertiary)
                .kerning(0.5)
            Text(value)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSSpacing.s3)
        .background(Color.htSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: DSRadius.card))
    }
}

// MARK: - Divider

struct DSDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.htBorderC)
            .frame(height: 0.5)
    }
}

// MARK: - Legacy aliases used across the project

struct DSSectionHeader: View {
    let title: String
    var count: Int? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"

    var body: some View {
        HStack {
            HTOverline(text: title)
            if let count {
                Text("\(count)")
                    .font(DSFont.caption())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.htSurfaceAlt, in: Capsule())
                    .foregroundStyle(Color.htFgSecondary)
            }
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(DSFont.caption())
                        .foregroundStyle(Color.htTint)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DSPill: View {
    let text: String
    var color: Color = .htTint
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                filled ? color : color.opacity(0.1),
                in: Capsule()
            )
            .foregroundStyle(filled ? Color.htBg : color)
    }
}

struct DSStreakBadge: View {
    let streak: Int
    var large: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Text("🔥").font(.system(size: large ? 14 : 10))
            Text("\(streak)")
                .font(.system(size: large ? 14 : 10, weight: .medium))
                .foregroundStyle(Color.htFireFg)
        }
        .padding(.horizontal, large ? 8 : 6)
        .padding(.vertical, large ? 4 : 2)
        .background(Color.htFireBg, in: Capsule())
    }
}

struct DSHabitAvatar: View {
    let emoji: String
    let color: Color
    var size: CGFloat = 44
    var completed: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(completed ? color.opacity(0.15) : color.opacity(0.12))
                .frame(width: size, height: size)
            Text(emoji)
                .font(.system(size: size * 0.5))
        }
    }
}

struct DSStatBadge: View {
    let value: String
    let label: String
    var color: Color = .htTint
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(color)
                }
                Text(value)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.htFgTertiary)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}
