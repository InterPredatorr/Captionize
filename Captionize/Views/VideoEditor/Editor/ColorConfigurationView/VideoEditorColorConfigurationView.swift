//
//  VideoEditorColorConfigurationView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 21.05.23.
//

import SwiftUI

struct VideoEditorColorConfigurationView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @Binding var colors: [VideoEditorColor]
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach($colors) { color in
                VideoEditorPickerView(viewModel: viewModel, item: color)
            }
            Spacer()
        }
    }
}

struct VideoEditorPickerView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @Binding var item: VideoEditorColor
    
    var body: some View {
        HStack {
            ColorPicker(item.name, selection: $item.color)
                .onChange(of: viewModel.settings.colors) { _ in
                    viewModel.updateColors()
                }
                .padding(.horizontal, 16)
        }
        .frame(height: Constants.VETextSettings.cellHeight)
        .background(Colors.appClayBlack)
        .cornerRadius(Constants.VECap.radius)
        .padding(.horizontal, 20)
    }
}
