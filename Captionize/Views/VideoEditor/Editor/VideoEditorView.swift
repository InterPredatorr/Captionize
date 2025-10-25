//
//  VideoEditorView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 20.04.23.
//

import SwiftUI

struct VideoEditorView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("", selection: $viewModel.captionsConfig.selectedEditor) {
                ForEach(Editor.allCases, id: \.rawValue) { editor in
                    Text(editor.rawValue)
                        .tag(editor)
                }
            }
            .onChange(of: viewModel.captionsConfig.selectedEditor, perform: { _ in
                viewModel.playerConfig.player.pause()
                viewModel.editorStates.isPlaying = false
                viewModel.editorStates.isAutoScrolling = false
            })
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, Constants.VETextSettings.itemsSpacing / 2)
            switch viewModel.captionsConfig.selectedEditor {
            case .text:
                VideoEditorTextConfigurationView(viewModel: viewModel)
                    .frame(height: UIScreen.screenHeight.percentageWith(percent: Constants.videoEditorConfigViewPercentage))
            case .resync:
                VideoEditorConfigurationView(viewModel: viewModel)
                    .frame(height: UIScreen.screenHeight.percentageWith(percent: Constants.videoEditorConfigViewPercentage))
            }
        }
    }
}
