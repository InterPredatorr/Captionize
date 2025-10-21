//
//  VideoPlayerView.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 17.04.23.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    let playerItemDidEndPublisher = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
    
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 10) {
                ZStack {
                    if viewModel.editorStates.isLoaded {
                        VideoPlayer(viewModel: viewModel)
                    }
                    if !viewModel.editorStates.isPlaying {
                        Button {
                            viewModel.editorStates.isPlaying = true
                            viewModel.editorStates.isAutoScrolling = true
                            viewModel.playerConfig.player.seek(to: CMTime(value: CMTimeValue(viewModel.playerConfig.currentTime * Constants.VPCap.timescale.toDouble),
                                                             timescale: Constants.VPCap.timescale),
                                                  toleranceBefore: .zero,
                                                  toleranceAfter: .zero)
                            viewModel.playerConfig.player.play()
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: reader.size.width, height: reader.size.height)
                Text(viewModel.playerConfig.videoTimeDescription)
            }
        }
        .onReceive(playerItemDidEndPublisher) { _ in
            if viewModel.editorStates.isPlaying {
                viewModel.playerConfig.player.seek(to: .zero)
                viewModel.playerConfig.player.pause()
                viewModel.editorStates.isPlaying = false
                viewModel.editorStates.isAutoScrolling = false
            }
        }
        .onDisappear {
            viewModel.playerConfig.player.pause()
        }
    }
}

