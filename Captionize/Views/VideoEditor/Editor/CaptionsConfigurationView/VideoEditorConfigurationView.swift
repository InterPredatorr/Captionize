//
//  VideoEditorConfigurationView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 20.04.23.
//

import SwiftUI
import Combine
import AVFoundation

struct VideoEditorConfigurationView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @State var points: Int = .zero
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                baseView
                currentTimeIndicatorView
            }
            Spacer().frame(height: 20)
            addAndRemoveButtons
        }
    }
    
    var baseView: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    autoScrollView
                        .onChange(of: viewModel.playerConfig.currentTime) { newValue in
                            if viewModel.editorStates.isAutoScrolling {
                                points = Int(newValue * Constants.VECap.secondToPoint + (Constants.VECap.secondToPoint / 2))
                                reader.scrollTo(points, anchor: .top)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    VideoEditorTimeView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Colors.appGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                    EditorCaptionView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                }
                .frame(width: Constants.VECap.secondToPoint * Double(viewModel.captionsConfig.seconds.count))
                .background(Colors.appClayBlack)
                .cornerRadius(Constants.VECap.radius)
                .padding(.horizontal, UIScreen.screenWidth / 2)
                .background(GeometryReader { proxy in
                    Color.clear.preference(
                        key: ViewWidthKeyScreen.self,
                        value: -1 * proxy.frame(in: .named("zScreen")).origin.x
                    )
                })
                .gesture(DragGesture().onChanged { _ in
                    viewModel.editorStates.isAutoScrolling = false
                })
                .onPreferenceChange(ViewWidthKeyScreen.self) {
                    viewModel.checkAvailibility()
                    viewModel.checkCaptionText()
                    viewModel.checkDurationText()
                    if !viewModel.editorStates.isAutoScrolling {
                        viewModel.seekToPoint($0)
                    }
                }
            }
            .coordinateSpace(name: "zScreen")
            .frame(height: Constants.videoEditorHeight)
        }
    }
    
    var currentTimeIndicatorView: some View {
        VStack(spacing: 0) {
            Image(systemName: "largecircle.fill.circle")
                .frame(width: 2, height: 2)
            RoundedRectangle(cornerRadius: 0)
                .frame(width: 2, height: Constants.videoEditorHeight - Constants.videoEditorTimerHeight)
        }
        .accessibilityRespondsToUserInteraction(false)
    }
    
    var autoScrollView: some View {
        LazyHStack(spacing: 0) {
            ForEach(0...(viewModel.captionsConfig.seconds.count * Int(Constants.VECap.secondToPoint)), id: \.self) { i in
                RoundedRectangle(cornerRadius: 0)
                    .frame(width: 1)
                    .foregroundColor(.clear)
                    .id(i)
            }
        }
        .frame(height: 1)
    }
    
    var addAndRemoveButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.removeCaption()
            } label: {
                HStack {
                    Spacer()
                    Text("-")
                        .font(.system(size: 50, weight: .light))
                    Spacer()
                }
                .background(Colors.appClayBlack)
                .cornerRadius(16 ,corners: [.topLeft, .bottomLeft])
            }
            .disabled(!viewModel.editorStates.isAbleToRemoveCaption)
            Button {
                viewModel.addNewCaption()
            } label: {
                HStack {
                    Spacer()
                    Text("+")
                        .font(.system(size: 50, weight: .light))
                    Spacer()
                }
                .background(Colors.appClayBlack)
                .cornerRadius(16 ,corners: [.topRight, .bottomRight])
            }
            .disabled(!viewModel.editorStates.isAbleToAddNewCaption)
        }
        .frame(height: 60)
        .padding()
    }
}

struct ViewWidthKeyScreen: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
