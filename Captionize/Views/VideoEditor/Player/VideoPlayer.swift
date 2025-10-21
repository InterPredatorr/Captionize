//
//  VideoPlayer.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 24.04.23.
//

import SwiftUI
import AVKit
import UIKit

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
        DispatchQueue.main.async {
            updateLabelConfig()
        }
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
        // Use only per-caption colors; default to white/appPurple if unset
        let currentTime = viewModel.playerConfig.currentTime + 0.5
        let activeItem = viewModel.captionsConfig.items.first(where: { $0.startPoint.toSeconds...$0.endPoint.toSeconds ~= currentTime })
        let defaultTextCG = UIColor.white.cgColor
        let ap = Colors.appPurple.components
        let defaultBgCG = UIColor(red: ap.red, green: ap.green, blue: ap.blue, alpha: ap.opacity).cgColor
        let textCG = CGColor.fromHexString(activeItem?.textColorHex) ?? defaultTextCG
        let bgCG = CGColor.fromHexString(activeItem?.backgroundColorHex) ?? defaultBgCG
        textLabel.backgroundColor = UIColor(cgColor: bgCG)
        textLabel.textColor = UIColor(cgColor: textCG)
        
        textLabel.frame.size.width = videoRect.width.percentageWith(percent: 80)
        textLabel.sizeToFit()
        let captionHeight = videoRect.height.percentageWith(percent: 20)
        if textLabel.frame.height > captionHeight {
            textLabel.frame.size.height = captionHeight
        }
        if let item = activeItem, let px = item.positionX, let py = item.positionY {
            let halfW = textLabel.frame.width / 2
            let halfH = textLabel.frame.height / 2
            var centerX = videoRect.minX + CGFloat(px) * videoRect.width
            var centerY = videoRect.minY + CGFloat(py) * videoRect.height
            // Clamp within bounds
            centerX = min(max(centerX, videoRect.minX + halfW), videoRect.maxX - halfW)
            centerY = min(max(centerY, videoRect.minY + halfH), videoRect.maxY - halfH)
            textLabel.layer.position = CGPoint(x: centerX, y: centerY)
        } else {
            let bottomSpace = captionHeight / 4
            let yPoint: CGFloat = videoRect.maxY - bottomSpace - (textLabel.frame.height / 2)
            textLabel.layer.position = CGPoint(x: videoRect.midX, y: yPoint)
        }
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
            playerLayer.frame = controller.view.bounds
            DispatchQueue.main.async {
                self.controller.player = self.videoPlayer.viewModel.playerConfig.player
            }
            controller.view.layer.addSublayer(playerLayer)
            if let overlay = controller.contentOverlayView {
                overlay.layer.addSublayer(self.videoPlayer.textLabel.layer)
            } else {
                controller.view.layer.addSublayer(self.videoPlayer.textLabel.layer)
            }
            controller.showsPlaybackControls = false
            // Initialize a safe video rect so captions appear on first open
            if self.videoPlayer.videoRect == .zero {
                let initial = self.controller.view.bounds
                self.videoPlayer.videoRect = initial
                self.videoPlayer.viewModel.playerConfig.videoRect = initial
            }
            // Enable dragging on the caption label
            self.videoPlayer.textLabel.isUserInteractionEnabled = true
            let pan = UIPanGestureRecognizer(target: self, action: #selector(Coordinator.handlePan(_:)))
            self.videoPlayer.textLabel.addGestureRecognizer(pan)
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
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            // Only allow dragging when a caption is active
            let currentTime = videoPlayer.viewModel.playerConfig.currentTime + 0.5
            guard let idx = videoPlayer.viewModel.captionsConfig.items.firstIndex(where: { $0.startPoint.toSeconds...$0.endPoint.toSeconds ~= currentTime }) else {
                return
            }
            let translation = recognizer.translation(in: controller.view)
            recognizer.setTranslation(.zero, in: controller.view)
            var newCenter = videoPlayer.textLabel.layer.position
            newCenter.x += translation.x
            newCenter.y += translation.y
            // Clamp within video bounds considering label size
            let rect = videoPlayer.videoRect
            let halfW = videoPlayer.textLabel.frame.width / 2
            let halfH = videoPlayer.textLabel.frame.height / 2
            newCenter.x = min(max(newCenter.x, rect.minX + halfW), rect.maxX - halfW)
            newCenter.y = min(max(newCenter.y, rect.minY + halfH), rect.maxY - halfH)
            videoPlayer.textLabel.layer.position = newCenter
            if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
                let xPerc = (newCenter.x - rect.minX) / rect.width
                let yPerc = (newCenter.y - rect.minY) / rect.height
                videoPlayer.viewModel.captionsConfig.items[idx].positionX = Double(xPerc)
                videoPlayer.viewModel.captionsConfig.items[idx].positionY = Double(yPerc)
            }
        }
        
        private func addVideoFrameObserver() {
            self.observer = controller.observe(\.videoBounds, options: [.new]) { [weak self] _, change in
                guard let self, let rect = change.newValue else { return }
                DispatchQueue.main.async {
                    self.videoPlayer.videoRect = rect
                    self.videoPlayer.viewModel.playerConfig.videoRect = rect
                    self.playerLayer.frame = rect
                    if let overlay = self.controller.contentOverlayView {
                        if self.videoPlayer.textLabel.layer.superlayer !== overlay.layer {
                            self.videoPlayer.textLabel.layer.removeFromSuperlayer()
                            overlay.layer.addSublayer(self.videoPlayer.textLabel.layer)
                        }
                    } else if self.videoPlayer.textLabel.layer.superlayer == nil {
                        self.controller.view.layer.addSublayer(self.videoPlayer.textLabel.layer)
                    }
                    if self.playerLayer.superlayer == nil {
                        self.controller.view.layer.addSublayer(self.playerLayer)
                    }
                    self.videoPlayer.viewModel.playerConfig.playerLayer = self.controller
                }
            }
        }
    }
}
