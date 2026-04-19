//
//  SettingsView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var theme = ThemeManager.shared
    private let themes = AppTheme.allCases as [AppTheme]

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                prideSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Appearance") {
            ForEach(themes, id: \.self) { t in
                AppThemeRow(t: t, isSelected: theme.current == t) {
                    theme.current = t
                }
            }
        }
    }

    @ViewBuilder
    private var prideSection: some View {
        Section(header: Text(theme.current == .pride ? "Pride palette" : "")) {
            if theme.current == .pride {
                HStack(spacing: 0) {
                    ForEach(theme.prideColors.indices, id: \.self) { i in
                        theme.prideColors[i]
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("Rainbow accents appear in your heatmap and streak badges.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
//            LabeledContent("Built with", value: "SwiftUI + SwiftData")
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func themeIcon(_ t: AppTheme) -> some View {
        if t == .pride {
            HStack(spacing: 2) {
                ForEach(ThemeManager.shared.prideColors.indices, id: \.self) { i in
                    ThemeManager.shared.prideColors[i]
                        .frame(width: 4, height: 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .frame(width: 28, height: 28)
        } else {
            Image(systemName: t.icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(t == .dark ? .indigo : t == .light ? .orange : .secondary)
        }
    }
}

// MARK: - Extracted Row (breaks ViewBuilder complexity)
private struct AppThemeRow: View {
    let t: AppTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            themeIcon(t)
            Text(t.rawValue)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private func themeIcon(_ t: AppTheme) -> some View {
        if t == .pride {
            HStack(spacing: 2) {
                ForEach(ThemeManager.shared.prideColors.indices, id: \.self) { i in
                    ThemeManager.shared.prideColors[i]
                        .frame(width: 4, height: 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .frame(width: 28, height: 28)
        } else {
            Image(systemName: t.icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(t == .dark ? .indigo : t == .light ? .orange : .secondary)
        }
    }
}
