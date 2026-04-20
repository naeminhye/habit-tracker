//
//  SettingsView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsSurface.ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DSSpacing.lg) {
                            tintSection
                            appearanceSection
                            aboutSection
                        }
                        .padding(DSSpacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SETTINGS")
                    .font(DSFont.capsLabel())
                    .foregroundStyle(Color.dsLabel)
                    .kerning(1)
                Text("Preferences")
                    .font(DSFont.title(20))
                    .foregroundStyle(Color.dsPrimaryText)
            }
            Spacer()
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.top, DSSpacing.md)
        .padding(.bottom, DSSpacing.sm)
    }

    // MARK: - Tint section

    private var tintSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Tint color")

            // Color grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 6),
                spacing: DSSpacing.md
            ) {
                ForEach(TintOption.all) { option in
                    TintColorCell(
                        option: option,
                        isSelected: theme.tint.id == option.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            theme.tint = option
                        }
                    }
                }
            }
            .padding(DSSpacing.md)
            .background(Color.dsBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 1)
            )

            // Live preview
            tintPreview
        }
    }

    // MARK: - Live preview

    private var tintPreview: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Preview")
                .font(DSFont.capsLabel(10))
                .foregroundStyle(Color.dsLabel)
                .kerning(0.5)

            HStack(spacing: DSSpacing.md) {
                // Progress ring preview
                ZStack {
                    Circle()
                        .stroke(Color.dsBorder, lineWidth: 6)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            theme.accentColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                    Text("70%")
                        .font(DSFont.caption(9))
                        .foregroundStyle(theme.accentColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Progress bar preview
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.dsBorder)
                                .frame(height: 6)
                            Capsule()
                                .fill(theme.accentColor)
                                .frame(width: geo.size.width * 0.65, height: 6)
                        }
                    }
                    .frame(height: 6)

                    // Button preview
                    HStack(spacing: DSSpacing.sm) {
                        Text("Today")
                            .font(DSFont.bodyBold(12))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(theme.accentColor, in: Capsule())
                            .foregroundStyle(.white)

                        Text("Pending")
                            .font(DSFont.bodyBold(12))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.dsBackground, in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(Color.dsBorder, lineWidth: 1)
                            )
                            .foregroundStyle(Color.dsPrimaryText)
                    }
                }
            }
            .padding(DSSpacing.md)
            .background(Color.dsBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Appearance section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Appearance")

            VStack(spacing: 2) {
                ForEach(AppAppearance.allCases, id: \.self) { option in
                    let isSelected = theme.appearance == option
                    Button {
                        withAnimation { theme.appearance = option }
                    } label: {
                        HStack(spacing: DSSpacing.md) {
                            Image(systemName: option.icon)
                                .font(.system(size: 15))
                                .foregroundStyle(
                                    isSelected ? theme.accentColor : Color.dsLabel
                                )
                                .frame(width: 28)
                            Text(option.rawValue)
                                .font(DSFont.body())
                                .foregroundStyle(Color.dsPrimaryText)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.accentColor)
                            }
                        }
                        .padding(DSSpacing.md)
                        .background(
                            isSelected
                                ? theme.accentColor.opacity(0.06)
                                : Color.dsBackground,
                            in: RoundedRectangle(cornerRadius: DSRadius.sm)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.dsBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "About")
            VStack(spacing: 0) {
                aboutRow(label: "Version", value: "1.0.0")
                DSDivider().padding(.horizontal, DSSpacing.md)
                aboutRow(label: "Author", value: "BangChitty")
            }
            .background(Color.dsBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 1)
            )
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(DSFont.body()).foregroundStyle(Color.dsPrimaryText)
            Spacer()
            Text(value).font(DSFont.body()).foregroundStyle(Color.dsLabel)
        }
        .padding(DSSpacing.md)
    }
}

// MARK: - TintColorCell

struct TintColorCell: View {
    let option: TintOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(option.color)
                    .frame(width: 36, height: 36)

                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
