//
//  StickerPickerView.swift
//  HabitTracker
//
//  Created by BangChitty on 20/04/2026.
//

import SwiftUI
import UIKit

// MARK: - Sticker item (image or emoji)

enum StickerItem {
    case emoji(String)
    case image(UIImage)
}

// MARK: - StickerPickerSheet

struct StickerPickerSheet: View {
    @Binding var selectedEmoji: String
    @Binding var selectedSticker: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var activeTab: StickerTab = .emoji
    
    enum StickerTab: String, CaseIterable {
        case emoji    = "Emoji"
        case stickers = "Stickers"
    }
    
    let decorations: [String] = [
        "⭐️","🔥","💪","✅","🎯","🏆","💯","🌟",
        "✨","🎉","🥳","💥","🚀","❤️","🩷","🧡",
        "💛","💚","💙","💜","🤍","🖤","☀️","🌈",
        "🌊","🌸","🍀","🦋","🐝","🎈","🎁","🍭",
        "😊","😎","🤩","🥰","😴","🤔","👏","🙌",
        "🫶","💫","🌙","⚡️","🍉","🍓","🎵","🎶",
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                HStack(spacing: 4) {
                    ForEach(StickerTab.allCases, id: \.self) { tab in
                        let isActive = activeTab == tab
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                activeTab = tab
                            }
                        } label: {
                            Text(tab.rawValue)
                                .font(DSFont.bodyBold(13))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    isActive ? Color.dsIndigo : Color.clear,
                                    in: RoundedRectangle(cornerRadius: DSRadius.sm)
                                )
                                .foregroundStyle(isActive ? .white : Color.dsLabel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(
                    Color.dsBorder.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: DSRadius.sm + 4)
                )
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.md)
                .padding(.bottom, DSSpacing.sm)
                
                DSDivider()
                
                if activeTab == .emoji {
                    emojiGrid
                } else {
                    deviceStickerPicker
                }
            }
            .navigationTitle("Choose a sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Emoji grid
    
    private var emojiGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 6),
                spacing: DSSpacing.sm
            ) {
                ForEach(decorations, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        selectedSticker = nil
                        dismiss()
                    } label: {
                        StickerText(text: emoji, fontSize: 32, outlineWidth: 2.5)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(
                                selectedEmoji == emoji
                                ? Color.dsIndigo.opacity(0.1)
                                : Color.clear,
                                in: RoundedRectangle(cornerRadius: DSRadius.sm)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DSSpacing.lg)
        }
    }
    
    // MARK: - Device sticker picker
    
    private var deviceStickerPicker: some View {
        DeviceStickerPickerRepresentable { image in
            selectedSticker = image
            selectedEmoji = ""
            dismiss()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Device sticker picker (UIKit bridge)

struct DeviceStickerPickerRepresentable: UIViewControllerRepresentable {
    let onSelect: (UIImage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Use emoji keyboard / sticker panel via UITextView trick
        let vc = StickerHostViewController()
        vc.onStickerSelected = onSelect
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class Coordinator {
        let onSelect: (UIImage) -> Void
        init(onSelect: @escaping (UIImage) -> Void) {
            self.onSelect = onSelect
        }
    }
}

// MARK: - StickerHostViewController

class StickerHostViewController: UIViewController,
                                 UITextViewDelegate {
    var onStickerSelected: ((UIImage) -> Void)?
    
    private let textView = UITextView()
    private let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(Color.dsSurface)
        
        // Instructions label
        label.text = "Tap below and use the emoji/sticker keyboard"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(Color.dsLabel)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Hidden text view to trigger keyboard
        textView.delegate = self
        textView.font = .systemFont(ofSize: 40)
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor(Color.dsBackground)
        textView.layer.cornerRadius = 14
        textView.layer.borderColor = UIColor(Color.dsBorder).cgColor
        textView.layer.borderWidth = 1
        textView.textAlignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        // Tap to focus button
        let tapBtn = UIButton(type: .system)
        tapBtn.setTitle("Open Sticker Keyboard", for: .normal)
        tapBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
//        tapBtn.setTitleColor(UIColor(Color.dsAccent), for: .normal)
//        tapBtn.backgroundColor = UIColor(Color.dsAccent.opacity(0.1))
//        tapBtn.layer.cornerRadius = 22
        tapBtn.configuration = {
            var config = UIButton.Configuration.filled()
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 12, leading: 24, bottom: 12, trailing: 24
            )
            config.baseBackgroundColor = UIColor(Color.dsAccent.opacity(0.1))
            config.baseForegroundColor = UIColor(Color.dsAccent)
            config.cornerStyle = .capsule
            return config
        }()
        tapBtn.addTarget(self, action: #selector(openKeyboard), for: .touchUpInside)
        tapBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tapBtn)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            textView.heightAnchor.constraint(equalToConstant: 80),
            
            tapBtn.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            tapBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    @objc private func openKeyboard() {
        textView.becomeFirstResponder()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Check if the user inserted an image attachment (sticker)
        let attributed = textView.attributedText
        attributed?.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attributed!.length)
        ) { value, _, stop in
            if let attachment = value as? NSTextAttachment,
               let image = attachment.image ??
                attachment.image(forBounds: .init(x: 0, y: 0, width: 100, height: 100),
                                 textContainer: nil,
                                 characterIndex: 0) {
                DispatchQueue.main.async {
                    self.onStickerSelected?(image)
                }
                stop.pointee = true
            }
        }
        
        // Also handle plain emoji text input
        let text = textView.text ?? ""
        if !text.isEmpty {
            let lastChar = String(text.suffix(1))
            if lastChar.unicodeScalars.first.map({ $0.value > 127 }) ?? false {
                // It's an emoji — but we handle sticker images above
                // Clear for next input
                textView.text = ""
            }
        }
    }
}
