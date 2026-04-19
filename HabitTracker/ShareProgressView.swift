//
//  ShareProgressView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData
import Photos

struct ShareProgressView: View {
    @Query var habits: [Habit]
    @Environment(\.dismiss) private var dismiss
    @State private var viewMode: ShareCardStyle = .month
    @State private var renderedImage: UIImage? = nil
    @State private var showingShareSheet = false
    @State private var isSavingToPhotos = false
    @State private var savedToPhotos = false
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    enum ShareCardStyle: String, CaseIterable {
        case month  = "Calendar"
        case habits = "Heatmap"
        case stats  = "Stats"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Style picker
                    Picker("Style", selection: $viewMode) {
                        ForEach(ShareCardStyle.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Live preview
                    shareCard
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                        .padding(.horizontal)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            renderAndShare()
                        } label: {
                            Label("Share…", systemImage: "square.and.arrow.up")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }

                        Button {
                            renderAndSaveToPhotos()
                        } label: {
                            HStack {
                                if isSavingToPhotos {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else if savedToPhotos {
                                    Image(systemName: "checkmark")
                                } else {
                                    Image(systemName: "photo.badge.arrow.down")
                                }
                                Text(savedToPhotos ? "Saved!" : "Save to Photos")
                                    .font(.body.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                savedToPhotos ? Color.green : Color.secondary.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(savedToPhotos ? .white : .primary)
                        }
                        .disabled(isSavingToPhotos)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let img = renderedImage {
                    ShareSheet(image: img)
                }
            }
        }
    }

    // MARK: - Share card

    @ViewBuilder
    private var shareCard: some View {
        switch viewMode {
        case .month:  monthCard
        case .habits: heatmapCard
        case .stats:  statsCard
        }
    }

    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Habit Progress")
                    .font(.headline)
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("🏆")
                .font(.title2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var cardFooter: some View {
        HStack {
            Spacer()
            Text("HabitTracker")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // Month card
    private var monthCard: some View {
        VStack(spacing: 0) {
            cardHeader
            MonthCalendarView()
                .frame(height: 380)
                .padding(.horizontal, 8)
            cardFooter
        }
        .background(Color(.systemBackground))
        .frame(width: 360)
    }

    // Heatmap card
    private var heatmapCard: some View {
        VStack(spacing: 12) {
            cardHeader
            VStack(spacing: 10) {
                ForEach(habits.prefix(3)) { habit in
                    HabitProgressCard(habit: habit)
                        .padding(.horizontal, 12)
                }
            }
            cardFooter
        }
        .background(Color(.systemBackground))
        .frame(width: 360)
    }

    // Stats card
    private var statsCard: some View {
        let completed = habits.filter(\.isCompletedToday).count
        let total = habits.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0
        let bestStreak = habits.map(\.currentStreak).max() ?? 0
        let totalCompletions = habits.flatMap(\.completedDates).count

        return VStack(spacing: 0) {
            cardHeader

            VStack(spacing: 16) {
                // Big progress ring
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 36, weight: .bold))
                        Text("today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 140, height: 140)
                .padding(.top, 8)

                // Stat grid
                HStack(spacing: 0) {
                    bigStat(value: "\(completed)/\(total)", label: "Done today")
                    Divider().frame(height: 44)
                    bigStat(value: "\(bestStreak)🔥", label: "Best streak")
                    Divider().frame(height: 44)
                    bigStat(value: "\(totalCompletions)", label: "All time")
                }
                .padding()
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                // Habit list with streaks
                VStack(spacing: 8) {
                    ForEach(habits.prefix(4)) { habit in
                        HStack(spacing: 10) {
                            Text(habit.emoji)
                            Text(habit.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            if habit.currentStreak > 0 {
                                Label("\(habit.currentStreak)", systemImage: "flame.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(habit.accentColor)
                            }
                            Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(
                                    habit.isCompletedToday ? habit.accentColor : Color.secondary
                                )
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 4)
            }

            cardFooter
        }
        .background(Color(.systemBackground))
        .frame(width: 360)
    }

    private func bigStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Render

    @MainActor
    private func renderAndShare() {
        let renderer = ImageRenderer(content: shareCard.padding(4))
        renderer.scale = UIScreen.main.scale
        renderedImage = renderer.uiImage
        showingShareSheet = true
    }

    @MainActor
    private func renderAndSaveToPhotos() {
        isSavingToPhotos = true
        let renderer = ImageRenderer(content: shareCard.padding(4))
        renderer.scale = UIScreen.main.scale
        guard let img = renderer.uiImage else {
            isSavingToPhotos = false
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    withAnimation { savedToPhotos = true }
                }
                isSavingToPhotos = false
            }
        }
    }
}
