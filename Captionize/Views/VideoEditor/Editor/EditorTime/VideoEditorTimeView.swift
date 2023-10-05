//
//  VideoEditorTimeView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 20.04.23.
//

import SwiftUI

struct VideoEditorTimeView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    
    var body: some View {
        LazyHGrid(rows: [GridItem(.fixed(Constants.VECap.secondToPoint))], spacing: 0) {
            ForEach(viewModel.captionsConfig.seconds, id: \.self) { second in
                VideoEditorTimeItemView(viewModel: viewModel, second: second)
            }
        }
        .frame(height: Constants.videoEditorTimerHeight)
    }
}
