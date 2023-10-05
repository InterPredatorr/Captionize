//
//  VideoEditorTextConfigurationView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 21.05.23.
//

import SwiftUI

struct VideoEditorTextConfigurationView: View {
    
    @ObservedObject var viewModel: VideoEditorViewModel
    
    var body: some View {
        VStack(spacing: Constants.VETextSettings.itemsSpacing) {
            fontPickerView
            fontSizePickerView
            alignmentPickerView
            capitalizationPickerView
        }
        .padding(.horizontal, Constants.VETextSettings.itemsSpacing / 2)
    }
        
    var fontPickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center) {
                VideoEditorSettingsCell(viewModel: viewModel,
                                        item: $viewModel.settings.customFont)
                    .frame(width: Constants.VETextSettings.constantSizedCellWidth)
                Divider()
                    .frame(width: 2)
                ForEach($viewModel.settings.fonts) { font in
                    VideoEditorSettingsCell(viewModel: viewModel,
                                            item: font)
                }
            }
        }
        .frame(height: Constants.VETextSettings.cellHeight)
    }
    
    var fontSizePickerView: some View {
        HStack {
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .frame(width: Constants.VETextSettings.constantSizedCellWidth,
                       height: Constants.VETextSettings.cellHeight)
                .background(Colors.appClayBlack)
                .cornerRadius(Constants.VETextSettings.cellCornerRadius)
            Divider().frame(width: 2)
            HStack {
                Image(systemName: "a")
                    .resizable()
                    .frame(width: 14, height: 16)
                Slider(value: $viewModel.settings.textSizeConfig.currentSize,
                       in: viewModel.settings.textSizeConfig.minSize...viewModel.settings.textSizeConfig.maxSize)
                Image(systemName: "a")
                    .resizable()
                    .frame(width: 27, height: 30)
            }
            .onChange(of: viewModel.settings.textSizeConfig.currentSize) { newValue in
                viewModel.captionsConfig.captionConfig.text.fontSize = newValue
            }
            .padding(.horizontal, Constants.VETextSettings.itemsSpacing)
            .frame(height: Constants.VETextSettings.cellHeight)
            .background(Colors.appClayBlack)
            .cornerRadius(Constants.VETextSettings.cellCornerRadius)
        }
        .frame(height: Constants.VETextSettings.cellHeight)
    }
    
    var alignmentPickerView: some View {
        HStack(spacing: 4) {
            ForEach($viewModel.settings.alignments) { item in
                CaptionTextAlignmentSettingView(viewModel: viewModel, item: item)
            }
        }
        .scaledToFill()
    }

    var capitalizationPickerView: some View {
        HStack(spacing: 2) {
            ForEach($viewModel.settings.capitalizationTypes) { type in
                CaptionCapitalizationSettingView(viewModel: viewModel, item: type)
            }
        }
    }
}

struct VideoEditorSettingsCell: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @Binding var item: VideoEditorFont
    
    var body: some View {
        Text(item.name)
            .font(Font(UIFont(name: item.font.name,
                              size: item.font.size) ?? .roboto(size: 20)))
            .frame(height: Constants.VETextSettings.cellHeight)
            .padding(.horizontal, 10)
            .background(item.isSelected ? Color.blue : Colors.appClayBlack)
            .cornerRadius(Constants.VETextSettings.cellCornerRadius)
            .onTapGesture {
                viewModel.captionsConfig.captionConfig.text.font = UIFont(name: item.font.name,
                                                                          size: item.font.size) ?? .roboto(size: 20)
                viewModel.settings.customFont.isSelected = viewModel.settings.customFont.id == item.id
                viewModel.settings.fonts = viewModel.settings.fonts.map { font in
                    var tmp = font
                    tmp.isSelected = tmp.id == item.id
                    return tmp
                }
            }
    }
}

struct CaptionCapitalizationSettingView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @Binding var item: CapitalizationType
    
    var body: some View {
        Button {
            viewModel.settings.capitalizationTypes = viewModel.settings.capitalizationTypes.map { type in
                var tmp = type
                tmp.isSelected = tmp.id == item.id
                return tmp
            }
            viewModel.changeTextCapitalization()
            viewModel.checkCaptionText()
        } label: {
            Text(item.type.rawValue)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .center)
        }
        .frame(height: Constants.VETextSettings.cellHeight)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
        .background(item.isSelected ? Color.blue : Colors.appClayBlack)
        .cornerRadius(Constants.VETextSettings.cellCornerRadius,
                      corners: item.type == .none ? [.topLeft,
                                                     .bottomLeft] : item.type == .ab ? [.topRight,
                                                                                                .bottomRight] : [])
    }
}


struct CaptionTextAlignmentSettingView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @Binding var item: VideoEditorAlignment
    @State var alignment: NSTextAlignment = .center
    
    var body: some View {
        Button {
            viewModel.captionsConfig.captionConfig.text.alignment = alignment
            viewModel.settings.alignments = viewModel.settings.alignments.map { alignment in
                var tmp = alignment
                tmp.isSelected = tmp.id == item.id
                return tmp
            }
        } label: {
            Image(systemName: item.iconName)
                .resizable()
                .frame(width: 34, height: 22)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .center)
        }
        .frame(height: Constants.VETextSettings.cellHeight)
        .frame(maxWidth: .infinity)
        .background(item.isSelected ? Color.blue : Colors.appClayBlack)
        .cornerRadius(Constants.VETextSettings.cellCornerRadius,
                      corners: alignment == .left ? [.topLeft,
                                                     .bottomLeft] : alignment == .center ? [] : [.topRight,
                                                                                                 .bottomRight])
        .onAppear {
            alignment = NSTextAlignment(rawValue: item.alignment) ?? .center
        }
    }
}
