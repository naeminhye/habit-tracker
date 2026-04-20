//
//  TagManagerView.swift
//  HabitTracker
//
//  Created by BangChitty on 19/04/2026.
//

import SwiftUI
import SwiftData

@MainActor
struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query var allTags: [Tag]
    @Binding var selectedTags: [Tag]

    @State private var newLabel = ""
    @State private var newColorHex = "007AFF"
    @State private var showingCreator = false

    var body: some View {
        NavigationStack {
            List {
                existingTagsSection
                newTagSection
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var existingTagsSection: some View {
        Section {
            if allTags.isEmpty {
                Text("No tags yet — create one below")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(allTags) { tag in
                    let isSelected = selectedTags.contains { $0.id == tag.id }
                    HStack(spacing: 12) {
                        Circle()
                            .fill(tag.color)
                            .frame(width: 12, height: 12)
                        Text(tag.label)
                            .font(.body)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelected {
                            selectedTags.removeAll { $0.id == tag.id }
                        } else {
                            selectedTags.append(tag)
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { context.delete(allTags[i]) }
                }
            }
        } header: {
            Text("Your tags")
        }
    }

    private var newTagSection: some View {
        Section {
            TextField("Label", text: $newLabel)
            HabitColorPicker(selectedHex: $newColorHex)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            Button {
                createTag()
            } label: {
                HStack {
                    Spacer()
                    Text("Create tag").bold()
                    Spacer()
                }
            }
            .disabled(newLabel.trimmingCharacters(in: .whitespaces).isEmpty)
        } header: {
            Text("New tag")
        }
    }
    
    private func createTag() {
        let tag = Tag(
            label: newLabel.trimmingCharacters(in: .whitespaces),
            colorHex: newColorHex
        )
        context.insert(tag)
        selectedTags.append(tag)
        newLabel = ""
        newColorHex = "007AFF"
    }
}
