//
//  ThemeManager.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

// MARK: - Appearance

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Tint colors

struct TintOption: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String
    var color: Color { Color(hex: hex) }
}

extension TintOption {
    static let all: [TintOption] = [
        TintOption(id: "teal",     name: "Teal",    hex: "4A9E8A"),  // oklch 0.62 0.11 165
        TintOption(id: "coral",    name: "Coral",   hex: "CC6B5A"),  // oklch 0.62 0.11 25
        TintOption(id: "orange",   name: "Orange",  hex: "B87840"),  // oklch 0.62 0.11 55
        TintOption(id: "yellow",   name: "Yellow",  hex: "8C8A30"),  // oklch 0.62 0.11 90
        TintOption(id: "mint",     name: "Mint",    hex: "3E9E70"),  // oklch 0.62 0.11 140
        TintOption(id: "green",    name: "Green",   hex: "3A9E7A"),  // oklch 0.62 0.11 185
        TintOption(id: "blue",     name: "Blue",    hex: "4A7ECC"),  // oklch 0.62 0.11 230
        TintOption(id: "indigo",   name: "Indigo",  hex: "6A5ECC"),  // oklch 0.62 0.11 265
        TintOption(id: "purple",   name: "Purple",  hex: "8A4ECC"),  // oklch 0.62 0.11 295
        TintOption(id: "pink",     name: "Pink",    hex: "CC4A7A"),  // oklch 0.62 0.11 340
        TintOption(id: "brown",    name: "Brown",   hex: "7A6050"),  // oklch 0.55 0.06 60
        TintOption(id: "graphite", name: "Graphite",hex: "7A7A72"),  // oklch 0.55 0.01 90
    ]

    static let `default` = TintOption.all.first { $0.id == "teal" } ?? TintOption.all[0]

}

// MARK: - ThemeManager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var tint: TintOption {
        didSet {
            UserDefaults.standard.set(tint.id, forKey: "appTintID")
        }
    }

    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance")
        }
    }

    var effectiveColorScheme: ColorScheme? { appearance.colorScheme }

    // Semantic colors derived from tint
    var accentColor: Color { tint.color }

    private init() {
        let savedTint = UserDefaults.standard.string(forKey: "appTintID") ?? "teal"  // ← teal
        tint = TintOption.all.first { $0.id == savedTint } ?? .default

        let savedApp = UserDefaults.standard.string(forKey: "appAppearance") ?? "System"
        appearance = AppAppearance(rawValue: savedApp) ?? .system
    }
}
