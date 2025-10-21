//
//  CaptionEditSheetView.swift
//  Captionize
//
//  Created by Junie (AI) on 20.10.25.
//

import SwiftUI
import UIKit

struct CaptionEditSheetView: View {
    @Binding var item: CaptionItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var textColor: Color = .white
    @State private var backgroundColor: Color = Colors.appPurple
    
    init(item: Binding<CaptionItem>) {
        self._item = item
        // Initialize _text, _textColor, _backgroundColor in body via onAppear to access CGColor helpers
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Caption text")) {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .font(.system(size: 16))
                }
                Section(header: Text("Colors")) {
                    ColorPicker("Text color", selection: $textColor, supportsOpacity: true)
                    ColorPicker("Background color", selection: $backgroundColor, supportsOpacity: true)
                }
                Section(header: Text("Preview")) {
                    HStack {
                        Spacer()
                        Text(text.isEmpty ? " " : text)
                            .foregroundColor(textColor)
                            .padding(12)
                            .background(backgroundColor)
                            .cornerRadius(8)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                self.text = item.captionText
                if let tcg = CGColor.fromHexString(item.textColorHex) {
                    self.textColor = Color(UIColor(cgColor: tcg))
                } else {
                    self.textColor = .white
                }
                if let bgcg = CGColor.fromHexString(item.backgroundColorHex) {
                    self.backgroundColor = Color(UIColor(cgColor: bgcg))
                } else {
                    self.backgroundColor = Colors.appPurple
                }
            }
            .onChange(of: text) { _ in
                item.captionText = text
            }
            .onChange(of: textColor) { _ in
                item.textColorHex = uiColor(from: textColor).cgColor.toHexString()
            }
            .onChange(of: backgroundColor) { _ in
                item.backgroundColorHex = uiColor(from: backgroundColor).cgColor.toHexString()
            }
        }
    }
    
    private func applyChanges() {
        item.captionText = text
        item.textColorHex = uiColor(from: textColor).cgColor.toHexString()
        item.backgroundColorHex = uiColor(from: backgroundColor).cgColor.toHexString()
    }
    
    private func uiColor(from color: Color) -> UIColor {
        let c = color.components
        return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.opacity)
    }
}
