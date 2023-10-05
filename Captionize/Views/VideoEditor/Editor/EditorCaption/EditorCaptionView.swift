//
//  EditorCaptionView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 30.04.23.
//

import SwiftUI

struct EditorCaptionView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @State var draggedItem: CaptionItem?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(zip(viewModel.captionsConfig.items.indices, viewModel.captionsConfig.items)), id: \.1.id) { index, item in
                Spacer()
                    .frame(width: viewModel.getSpacerWidth(at: index))
                CaptionItemView(viewModel: viewModel, item: $viewModel.captionsConfig.items[index])
                    .onDrag {
                        self.draggedItem = item
                        return NSItemProvider()
                    }
                    .onDrop(of: [.text],
                            delegate: DropViewDelegate(destinationItem: item,
                                                       texts: $viewModel.captionsConfig.items,
                                                       draggedItem: $draggedItem)
                    )
                if index == viewModel.captionsConfig.items.count - 1 {
                    Spacer().frame(width: (Double(viewModel.captionsConfig.seconds.count) * Constants.VECap.secondToPoint - item.endPoint).unsigned)
                }
            }
        }
        .coordinateSpace(name: "captionSpace")
        .frame(height: Constants.videoEditorHeight - Constants.videoEditorTimerHeight - 1)
    }
}
