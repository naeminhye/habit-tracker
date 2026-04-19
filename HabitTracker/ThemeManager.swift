//
//  ThemeManager.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"
    case pride  = "Pride"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        case .pride:  return nil
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .pride:  return "rainbow"
        }
    }
}

@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    var current: AppTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "appTheme") }
    }
    
    // Pride rainbow stops cycled as accent
    let prideColors: [Color] = [
        Color(hex: "FF0018"), // red
        Color(hex: "FFA52C"), // orange
        Color(hex: "FFFF41"), // yellow
        Color(hex: "008018"), // green
        Color(hex: "0000F9"), // blue
        Color(hex: "86007D"), // violet
    ]
    
    // Returns color for a given index position (heatmap cells, accents)
    func prideColor(at index: Int) -> Color {
        prideColors[index % prideColors.count]
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? ""
        current = AppTheme(rawValue: saved) ?? .system
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double(v         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
