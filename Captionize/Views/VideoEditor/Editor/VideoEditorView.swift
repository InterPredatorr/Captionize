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
            })
            .pickerStyle(.segmented)
            .labelsHidden()
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
