//
//  VideoEditorTimeItemView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 30.04.23.
//

import SwiftUI

struct VideoEditorTimeItemView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    var secondWidth = Constants.VECap.secondToPoint
    var second: String
    
    var body: some View {
        HStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 0)
                .background(Colors.appGray)
                .frame(width: 1, height: 5)
            Spacer().frame(width: secondWidth / 2 - 1)
            RoundedRectangle(cornerRadius: 0)
                .background(Colors.appGray)
                .frame(width: 1, height: 10)
            Text(second)
                .font(Font.roboto(size: 10))
                .minimumScaleFactor(0.1)
                .frame(width: secondWidth / 2 - 1,
                       height: Constants.videoEditorTimerHeight, alignment: .leading)
        }
        .frame(width: secondWidth)
    }
}
