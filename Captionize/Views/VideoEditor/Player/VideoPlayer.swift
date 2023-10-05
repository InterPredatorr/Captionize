//
//  VideoPlayer.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 24.04.23.
//

import SwiftUI
import AVKit

struct VideoPlayer: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: VideoEditorViewModel
    @State var textLabel = UILabel()
    @State var videoRect = CGRect.zero
    //MARK: - View Setup
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayer>) -> AVPlayerViewController {
        return context.coordinator.controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController,
                                context: UIViewControllerRepresentableContext<VideoPlayer>) {
        updateLabelConfig()
    }

    func makeCoordinator() -> Coordinator {
        setupLabel()
        return Coordinator(self)
    }
    
    private func setupLabel() {
        textLabel.numberOfLines = 10
    }
    
    private func updateLabelConfig() {
        let config = viewModel.captionsConfig.captionConfig
        textLabel.text = viewModel.playerConfig.captionText
        textLabel.isHidden = viewModel.playerConfig.captionText.isEmpty
        textLabel.font = config.text.font
        textLabel.font = textLabel.font.withSize(config.text.fontSize)
        textLabel.textAlignment = config.text.alignment
        textLabel.backgroundColor = UIColor(cgColor: config.background.color)
        textLabel.textColor = UIColor(cgColor: config.text.color)
        
        textLabel.sizeToFit()
        textLabel.frame.size.width = videoRect.width.percentageWith(percent: 80)
        if textLabel.frame.height > videoRect.height.percentageWith(percent: 90) {
            textLabel.frame.size.height = videoRect.height.percentageWith(percent: 90)
        }
        let bottomSpace = videoRect.height.percentageWith(percent: 20) / 4
        let yPoint: CGFloat = videoRect.maxY - bottomSpace - (textLabel.frame.height / 2)
        textLabel.layer.position = CGPoint(x: videoRect.midX, y: yPoint)
    }
}

extension VideoPlayer {
    
    class Coordinator {
        let controller = AVPlayerViewController()
        var videoPlayer: VideoPlayer
        var observer: NSKeyValueObservation?
        var playerLayer = AVPlayerLayer()

        
        init(_ videoPlayer: VideoPlayer) {
            self.videoPlayer = videoPlayer
            addVideoFrameObserver()
            addTapGesture()
            setupPlayer()
        }
        
        private func setupPlayer() {
            playerLayer = AVPlayerLayer(player: self.videoPlayer.viewModel.playerConfig.player)
            playerLayer.addSublayer(self.videoPlayer.textLabel.layer)
            controller.player = self.videoPlayer.viewModel.playerConfig.player
            controller.view.layer.addSublayer(playerLayer)
            controller.showsPlaybackControls = false
        }
        private func addTapGesture() {
            let tapGesture = UITapGestureRecognizer(target: self,
                                                    action: #selector(Coordinator.handleTapGesture))
            controller.view.addGestureRecognizer(tapGesture)
        }
        
        @objc func handleTapGesture() {
            if videoPlayer.viewModel.playerConfig.player.timeControlStatus == .playing {
                videoPlayer.viewModel.playerConfig.player.pause()
                videoPlayer.viewModel.editorStates.isPlaying = false
                videoPlayer.viewModel.editorStates.isAutoScrolling = false
            }
        }
        
        private func addVideoFrameObserver() {
            self.observer = controller.observe(\.videoBounds, options: [.new],
                                                changeHandler: { [weak self] _, change in
                guard let self, let rect = change.newValue else { return }
                self.videoPlayer.videoRect = rect
                self.videoPlayer.viewModel.playerConfig.videoRect = rect
                playerLayer.addSublayer(self.videoPlayer.textLabel.layer)
                controller.view.layer.addSublayer(playerLayer)
                videoPlayer.viewModel.playerConfig.playerLayer = controller
            })
        }
    }
}
