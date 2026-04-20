# HabitTracker

A beautiful, fully-featured iOS habit tracking app built with SwiftUI and SwiftData.

---

## Screenshots

> Add your screenshots here after running on device/simulator.

---

## Features

### Today Tab
- Streak strip showing last 7 days with 🔥 fire and 🧊 frozen fire (Duolingo-style)
- Progress bar for habits done today
- Filter by All / Pending / Done / Tag
- Search habits by name, description, or tag
- Swipe left to delete, swipe right to edit
- Tap to complete with decoration picker
- Due today vs Upcoming sections for non-daily habits

### Habits
- Name, emoji, description, color accent, tags
- **Frequency:** Daily, Weekly, Monthly, Every N days, Specific days of week
- Start date + optional end date
- Reminders via local notifications
- Per-habit focus timer with adjustable duration

### Goals
- **Types:** Complete once, N times per period, or reach a target amount (e.g. 2 liters, 30 minutes)
- Period: per day, week, or month
- Inline progress bar in habit row
- Amount logging sheet with quick-add chips

### Focus Timer
- Per-habit timer linked to habit duration
- Adjustable duration before starting (5–120 min presets)
- **Deep focus mode** — locks the screen, no pausing or exiting (uses Guided Access)
- Session history: today's sessions + recent
- Auto-completes habit when timer finishes

### Progress Tab
- **Month calendar view** — full grid with emoji stickers on each completed day
- **Habit heatmap view** — 5-week completion grid per habit
- Toggle between views from top-left switcher
- Share progress as image (Calendar, Heatmap, or Stats card style)

### Achievements Tab
- **Badges** — unlocked (gold ring) and locked (dashed ring silhouette)
- **Milestones** — 10 default milestones + custom milestone creator
- Per-habit milestone progress with next milestone preview
- Banner notification when a milestone is reached

### Decoration & Stickers
- Quick emoji grid (40+ options)
- Browse device sticker library
- iOS 17 white outline sticker effect
- Preview before applying
- Sticker shown as badge on habit avatar in the list

### Widgets
- **Home screen:** Small (progress ring) + Medium (habit list with streaks)
- **Lock screen:** Circular (gauge), Rectangular (top 2 habits), Inline (streak + count)
- Auto-refreshes at midnight

### Settings
- 12 tint color options (Coral, Indigo, Teal, Blue, Mint, Purple, Pink, Orange, Yellow, Green, Brown, Graphite)
- Light / Dark / System appearance
- Live preview of tint applied to UI elements

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Data | SwiftData |
| Widgets | WidgetKit |
| Notifications | UserNotifications |
| Focus lock | UIAccessibility (Guided Access) |
| Sharing | ImageRenderer + UIActivityViewController |
| Storage | App Groups (shared between app + widget) |
| Min target | iOS 17 |

---

## Project Structure

```
HabitTracker/
├── Models/
│   ├── Habit.swift
│   ├── Tag.swift
│   ├── HabitGoal.swift
│   ├── FocusSession.swift
│   ├── Milestone.swift
│   └── Badge.swift
├── Views/
│   ├── Today/
│   │   ├── ContentView.swift
│   │   ├── HabitRowView.swift
│   │   └── StreakStripView.swift
│   ├── Progress/
│   │   ├── ProgressView.swift
│   │   └── MonthCalendarView.swift
│   ├── Focus/
│   │   ├── FocusTabView.swift
│   │   └── FocusTimerView.swift
│   ├── Achievements/
│   │   ├── AchievementsView.swift
│   │   └── CustomMilestoneCreator.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Shared/
│       ├── DecorationPickerView.swift
│       ├── StickerPickerView.swift
│       ├── AddHabitView.swift
│       ├── GoalSetupView.swift
│       ├── GoalProgressView.swift
│       ├── TagManagerView.swift
│       ├── EmojiPickerView.swift
│       └── WeekdayPicker.swift
├── Components/
│   ├── StickerText.swift
│   ├── TagBadge.swift
│   ├── HabitColorPicker.swift
│   └── MilestoneBannerView.swift
├── Design/
│   └── DesignSystem.swift
├── Engine/
│   └── MilestoneEngine.swift
├── Managers/
│   ├── ThemeManager.swift
│   ├── NotificationManager.swift
│   └── SharedStore.swift
├── Migration/
│   └── HabitMigrationPlan.swift
└── HabitWidgets/
    └── HabitWidgets.swift
```

---

## Getting Started

### Requirements
- Xcode 16+ (Xcode 17 for iOS 26)
- macOS Sequoia 15+ (for Xcode 17)
- iOS 17+ deployment target

### Setup

1. **Clone the repo**
```bash
git clone https://github.com/yourname/HabitTracker.git
cd HabitTracker
open HabitTracker.xcodeproj
```

2. **Configure signing**
   - Select the `HabitTracker` target
   - Go to **Signing & Capabilities**
   - Set your **Team** to your Apple ID
   - Repeat for the `HabitWidgets` target

3. **Configure App Group**
   - In `SharedStore.swift`, update:
   ```swift
   static let appGroupID = "group.com.yourname.habittracker"
   ```
   - Make sure the same App Group is added in both targets under **Signing & Capabilities**

4. **Run**
   - Select a simulator or connected device
   - Hit **⌘+R**

---

## Architecture Notes

- **SwiftData** handles all persistence with a shared `ModelContainer` via App Groups so widgets can read the same data
- **Schema migrations** are handled with lightweight migrations through `HabitMigrationPlan` — currently at V6
- **ThemeManager** is `@Observable` and drives the tint color globally via `.tint()` on the root `TabView`
- **MilestoneEngine** runs on every habit toggle and checks all milestones, unlocking badges automatically
- All views are `@MainActor` isolated to avoid SwiftData cross-context relationship crashes

---

## Known Limitations

- iCloud sync requires a paid Apple Developer account ($99/year) — currently disabled (`cloudKitDatabase: .none`)
- Device sticker picker uses a `UITextView` bridge — stickers from some packs may not be captured
- Deep focus mode requires the user to enable Guided Access once in **Settings → Accessibility → Guided Access**
- Widgets show placeholder data if App Groups are not configured

---

## License

MIT License — see `LICENSE` for details.

---

## Built with ❤️ by BangChitty
