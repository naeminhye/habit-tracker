//
//  SettingsView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var theme = ThemeManager.shared
    @State private var remindersEnabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
    @State private var milestoneBannersEnabled = UserDefaults.standard.bool(forKey: "milestoneBanners") == false ? true : UserDefaults.standard.bool(forKey: "milestoneBanners")
    @State private var dailySummaryEnabled = UserDefaults.standard.bool(forKey: "dailySummary")
    @State private var summaryTime = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsPageBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    navBar
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DSSpacing.lg) {
                            tintSection
                            appearanceSection
                            notificationsSection
                            widgetsSection
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
                    .font(DSFont.overline())
                    .foregroundStyle(Color.dsLabel)
                    .kerning(1)
                Text("Preferences")
                    .font(DSFont.displayM())
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

            // Single scrollable row of dots per spec
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.md) {
                    ForEach(TintOption.all) { option in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                theme.tint = option
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 28, height: 28)
                                if theme.tint.id == option.id {
                                    Circle()
                                        .strokeBorder(Color.dsPrimaryText,
                                                      lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                        .padding(2)
                                }
                            }
                            .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.name)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.sm)
            }
            .background(Color.dsCardBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
            )

            // Live preview
            tintPreview
        }
    }
    
    // MARK: - Live preview
    
    private var tintPreview: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Preview")
                .font(DSFont.overline())
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

            // Segmented control per spec
            HStack(spacing: 0) {
                ForEach(AppAppearance.allCases, id: \.self) { option in
                    let isActive = theme.appearance == option
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            theme.appearance = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(
                                isActive ? Color.dsPrimaryText : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .foregroundStyle(isActive ? .white : Color.dsLabel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.dsCardBackground,
                        in: RoundedRectangle(cornerRadius: 11))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Notification section
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Notifications")

            VStack(spacing: 0) {
                settingsRow {
                    Toggle("Habit reminders", isOn: $remindersEnabled)
                        .font(DSFont.body())
                        .onChange(of: remindersEnabled) { _, val in
                            UserDefaults.standard.set(val, forKey: "remindersEnabled")
                        }
                }
                DSDivider().padding(.horizontal, DSSpacing.md)
                settingsRow {
                    Toggle("Milestone banners", isOn: $milestoneBannersEnabled)
                        .font(DSFont.body())
                        .onChange(of: milestoneBannersEnabled) { _, val in
                            UserDefaults.standard.set(val, forKey: "milestoneBanners")
                        }
                }
                DSDivider().padding(.horizontal, DSSpacing.md)
                settingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Daily summary", isOn: $dailySummaryEnabled)
                            .font(DSFont.body())
                            .onChange(of: dailySummaryEnabled) { _, val in
                                UserDefaults.standard.set(val, forKey: "dailySummary")
                            }
                        if dailySummaryEnabled {
                            DatePicker("Time", selection: $summaryTime,
                                       displayedComponents: .hourAndMinute)
                                .font(DSFont.caption())
                                .foregroundStyle(Color.dsLabel)
                        }
                    }
                }
            }
            .background(Color.dsBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Widgets section
    
    private var widgetsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            DSSectionHeader(title: "Widgets")

            VStack(spacing: 0) {
                settingsRow {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Configure widgets from the iOS home screen")
                            .font(DSFont.body())
                            .foregroundStyle(Color.dsPrimaryText)
                        Text("Long-press the home screen → tap + → search Habit Tracker")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                    }
                }
                DSDivider().padding(.horizontal, DSSpacing.md)
                settingsRow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available widgets")
                            .font(DSFont.body())
                            .foregroundStyle(Color.dsPrimaryText)
                        Text("Home screen: Small (ring), Medium (habit list)\nLock screen: Circular, Rectangular, Inline")
                            .font(DSFont.caption())
                            .foregroundStyle(Color.dsLabel)
                    }
                }
            }
            .background(Color.dsBackground,
                        in: RoundedRectangle(cornerRadius: DSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .strokeBorder(Color.dsBorder, lineWidth: 0.5)
            )
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(DSSpacing.md)
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
