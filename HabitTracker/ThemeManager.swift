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
        TintOption(id: "coral",    name: "Coral",    hex: "FF6B4A"),
        TintOption(id: "indigo",   name: "Indigo",   hex: "5856D6"),
        TintOption(id: "teal",     name: "Teal",     hex: "00C7BE"),
        TintOption(id: "blue",     name: "Blue",     hex: "007AFF"),
        TintOption(id: "mint",     name: "Mint",     hex: "00C896"),
        TintOption(id: "purple",   name: "Purple",   hex: "AF52DE"),
        TintOption(id: "pink",     name: "Pink",     hex: "FF2D55"),
        TintOption(id: "orange",   name: "Orange",   hex: "FF9500"),
        TintOption(id: "yellow",   name: "Yellow",   hex: "FFCC00"),
        TintOption(id: "green",    name: "Green",    hex: "34C759"),
        TintOption(id: "brown",    name: "Brown",    hex: "A2845E"),
        TintOption(id: "graphite", name: "Graphite", hex: "636366"),
    ]
    static let `default` = TintOption.all[0]
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
        let savedTint = UserDefaults.standard.string(forKey: "appTintID") ?? "coral"
        tint = TintOption.all.first { $0.id == savedTint } ?? .default

        let savedApp = UserDefaults.standard.string(forKey: "appAppearance") ?? "System"
        appearance = AppAppearance(rawValue: savedApp) ?? .system
    }
}
