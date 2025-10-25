//
//  VideoPlayer.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 24.04.23.
//

import SwiftUI
import AVKit
import UIKit
import Combine

struct VideoPlayer: UIViewControllerRepresentable {

    @ObservedObject var viewModel: VideoEditorViewModel

    //MARK: - View Setup

    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayer>) -> AVPlayerViewController {
        return context.coordinator.controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController,
                                context: UIViewControllerRepresentableContext<VideoPlayer>) {
        // Update player reference if it changed
        if context.coordinator.controller.player !== viewModel.playerConfig.player {
            context.coordinator.controller.player = viewModel.playerConfig.player
        }
        // Ensure text detection remains disabled
        uiViewController.allowsVideoFrameAnalysis = false
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }
}

extension VideoPlayer {

    class Coordinator: NSObject {
        let controller = AVPlayerViewController()
        let viewModel: VideoEditorViewModel

        private var videoBoundsObserver: NSKeyValueObservation?
        private var captionUpdateTimer: Any?
        private let captionLabel = UILabel()

        private var currentVideoRect: CGRect = .zero
        private var cancellables = Set<AnyCancellable>()

        init(viewModel: VideoEditorViewModel) {
            self.viewModel = viewModel
            super.init()
            setupPlayerController()
            setupCaptionLabel()
            addGestures()
            observeVideoBounds()
            startCaptionUpdates()
            observeConfigurationChanges()
        }

        private func setupPlayerController() {
            controller.player = viewModel.playerConfig.player
            controller.showsPlaybackControls = false
            controller.videoGravity = .resizeAspect
            controller.allowsVideoFrameAnalysis = false
        }

        private func setupCaptionLabel() {
            captionLabel.numberOfLines = 0
            captionLabel.lineBreakMode = .byWordWrapping
            captionLabel.textAlignment = .center
            captionLabel.isUserInteractionEnabled = true
            captionLabel.layer.zPosition = 1000
            captionLabel.clipsToBounds = true
            captionLabel.layer.cornerRadius = 8
            captionLabel.adjustsFontSizeToFitWidth = false

            // Add label to content overlay if available
            if let overlay = controller.contentOverlayView {
                overlay.addSubview(captionLabel)
            } else {
                controller.view.addSubview(captionLabel)
            }
        }

        private func addGestures() {
            // Pan gesture for moving captions
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            captionLabel.addGestureRecognizer(panGesture)

            // Tap gesture for play/pause
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapGesture.require(toFail: panGesture)
            controller.view.addGestureRecognizer(tapGesture)
        }

        private func observeVideoBounds() {
            videoBoundsObserver = controller.observe(\.videoBounds, options: [.new, .initial]) { [weak self] _, change in
                guard let self = self, let rect = change.newValue, rect != .zero else { return }
                self.currentVideoRect = rect
                self.viewModel.playerConfig.videoRect = rect
                self.updateCaptionDisplay()
            }
        }

        private func startCaptionUpdates() {
            // Update captions at UI tick frequency (15 times per second)
            let interval = CMTime(value: 1, timescale: Constants.VPCap.uiTickPerSecond)
            captionUpdateTimer = viewModel.playerConfig.player.addPeriodicTimeObserver(
                forInterval: interval,
                queue: .main
            ) { [weak self] _ in
                self?.updateCaptionDisplay()
            }
        }

        private func observeConfigurationChanges() {
            // Observe caption configuration changes for real-time preview
            viewModel.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.updateCaptionDisplay()
                    }
                }
                .store(in: &cancellables)
        }

        private func updateCaptionDisplay() {
            guard currentVideoRect != .zero else { return }

            // Use the same 0.5 second offset as the timeline to sync caption display with the timeline indicator
            let currentTime = viewModel.playerConfig.currentTime + 0.5

            // Find active caption at current time (with offset to match timeline)
            let activeCaption = viewModel.captionsConfig.items.first { caption in
                let startTime = caption.startPoint.toSeconds
                let endTime = caption.endPoint.toSeconds
                return currentTime >= startTime && currentTime <= endTime
            }

            guard let caption = activeCaption, !caption.captionText.isEmpty else {
                captionLabel.isHidden = true
                return
            }

            captionLabel.isHidden = false
            captionLabel.text = caption.captionText

            // Apply text configuration
            let config = viewModel.captionsConfig.captionConfig
            captionLabel.font = config.text.font.withSize(config.text.fontSize)
            captionLabel.textAlignment = config.text.alignment

            // Ensure proper text rendering for multiline
            captionLabel.numberOfLines = 0
            captionLabel.lineBreakMode = .byWordWrapping

            // Apply colors
            let defaultTextColor = UIColor.white
            let ap = Colors.appPurple.components
            let defaultBgColor = UIColor(red: ap.red, green: ap.green, blue: ap.blue, alpha: ap.opacity)

            if let textColorHex = caption.textColorHex, let textCG = CGColor.fromHexString(textColorHex) {
                captionLabel.textColor = UIColor(cgColor: textCG)
            } else {
                captionLabel.textColor = defaultTextColor
            }

            if let bgColorHex = caption.backgroundColorHex, let bgCG = CGColor.fromHexString(bgColorHex) {
                captionLabel.backgroundColor = UIColor(cgColor: bgCG)
            } else {
                captionLabel.backgroundColor = defaultBgColor
            }

            // Calculate size with proper padding
            let maxWidth = currentVideoRect.width * 0.8
            let maxHeight = currentVideoRect.height * 0.25

            // Add padding for background
            let horizontalPadding: CGFloat = 16
            let verticalPadding: CGFloat = 8

            // Calculate the size that fits the text with word wrapping
            let availableWidth = maxWidth - (horizontalPadding * 2)
            let textSize = captionLabel.sizeThatFits(CGSize(width: availableWidth, height: maxHeight - (verticalPadding * 2)))

            let labelSize = CGSize(
                width: min(textSize.width + (horizontalPadding * 2), maxWidth),
                height: min(textSize.height + (verticalPadding * 2), maxHeight)
            )

            // Position the label
            let centerX: CGFloat
            let centerY: CGFloat

            if let posX = caption.positionX, let posY = caption.positionY,
               posX >= 0, posY >= 0, posX <= 1, posY <= 1 {
                // Use custom position
                centerX = currentVideoRect.minX + (currentVideoRect.width * CGFloat(posX))
                centerY = currentVideoRect.minY + (currentVideoRect.height * CGFloat(posY))
            } else {
                // Default to bottom center
                centerX = currentVideoRect.midX
                let bottomOffset = currentVideoRect.height * 0.1
                centerY = currentVideoRect.maxY - bottomOffset - (labelSize.height / 2)
            }

            // Clamp to video bounds
            let halfW = labelSize.width / 2
            let halfH = labelSize.height / 2
            let clampedX = min(max(centerX, currentVideoRect.minX + halfW), currentVideoRect.maxX - halfW)
            let clampedY = min(max(centerY, currentVideoRect.minY + halfH), currentVideoRect.maxY - halfH)

            captionLabel.frame = CGRect(
                x: clampedX - halfW,
                y: clampedY - halfH,
                width: labelSize.width,
                height: labelSize.height
            )
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            if viewModel.playerConfig.player.timeControlStatus == .playing {
                viewModel.playerConfig.player.pause()
                viewModel.editorStates.isPlaying = false
                viewModel.editorStates.isAutoScrolling = false
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            // Use the same 0.5 second offset as the timeline to match the indicator position
            let currentTime = viewModel.playerConfig.currentTime + 0.5

            // Find the active caption at the timeline indicator position
            guard let captionIndex = viewModel.captionsConfig.items.firstIndex(where: { caption in
                let startTime = caption.startPoint.toSeconds
                let endTime = caption.endPoint.toSeconds
                return currentTime >= startTime && currentTime <= endTime
            }) else {
                return
            }

            let translation = recognizer.translation(in: controller.view)
            recognizer.setTranslation(.zero, in: controller.view)

            var newCenter = captionLabel.center
            newCenter.x += translation.x
            newCenter.y += translation.y

            // Clamp to video bounds
            let halfW = captionLabel.frame.width / 2
            let halfH = captionLabel.frame.height / 2
            newCenter.x = min(max(newCenter.x, currentVideoRect.minX + halfW), currentVideoRect.maxX - halfW)
            newCenter.y = min(max(newCenter.y, currentVideoRect.minY + halfH), currentVideoRect.maxY - halfH)

            captionLabel.center = newCenter

            // Save position when gesture ends
            if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
                let normalizedX = (newCenter.x - currentVideoRect.minX) / currentVideoRect.width
                let normalizedY = (newCenter.y - currentVideoRect.minY) / currentVideoRect.height

                viewModel.captionsConfig.items[captionIndex].positionX = Double(normalizedX)
                viewModel.captionsConfig.items[captionIndex].positionY = Double(normalizedY)
            }
        }

        deinit {
            if let timer = captionUpdateTimer {
                viewModel.playerConfig.player.removeTimeObserver(timer)
            }
            videoBoundsObserver?.invalidate()
        }
    }
}
