//
//  VideoExportManager.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 14.05.23.
//

import Photos
import UIKit
import AVFoundation
import Foundation
import SwiftUI

public var isSimulator: Bool {
  #if targetEnvironment(simulator)
  true
  #else
  false
  #endif
}

class VideoExportManager {
    
    var composition: AVMutableComposition?
    var videoComposition: AVMutableVideoComposition?
    var exportSession: AVAssetExportSession?
    let config: VideoEditorViewModel.CaptionsConfig
    let playerConfig: VideoEditorViewModel.VideoPlayerConfig
    let asset: AVAsset?
    
    init(config: VideoEditorViewModel.CaptionsConfig, playerConfig: VideoEditorViewModel.VideoPlayerConfig, asset: AVAsset?) {
        self.config = config
        self.playerConfig = playerConfig
        self.asset = asset
    }
    
    func getVideoFrame(from rect: CGRect) -> CGRect {
        let tenPercentOfWidth = rect.width.percentageWith(percent: 10)
        let captionHeight = rect.height.percentageWith(percent: 20)
        return CGRect(x: rect.minX + tenPercentOfWidth,
                      y: captionHeight / 4,
                      width: rect.width - (2 * tenPercentOfWidth),
                      height: captionHeight)
    }
    
    func newCaptionTextLayerWith(_ item: CaptionItem, frame: CGRect, naturalFontSize: CGFloat, videoDuration: Double) -> CALayer {
        // Calculate padding scaled to video resolution to match preview proportions
        // The scaleFactor ensures padding grows proportionally with video resolution
        let scaleFactor = frame.width / playerConfig.videoRect.width
        let horizontalPadding: CGFloat = 16 * scaleFactor
        let verticalPadding: CGFloat = 8 * scaleFactor
        let cornerRadius: CGFloat = 8 * scaleFactor

        // Calculate maximum size
        let maxWidth = frame.width * 0.8
        let maxHeight = frame.height * 0.25

        // Colors
        let ap = Colors.appPurple.components
        let defaultBgCG = UIColor(red: ap.red, green: ap.green, blue: ap.blue, alpha: ap.opacity).cgColor
        let defaultTextCG = UIColor.white.cgColor
        let bgCG = CGColor.fromHexString(item.backgroundColorHex) ?? defaultBgCG
        let textCG = CGColor.fromHexString(item.textColorHex) ?? defaultTextCG

        // Create text layer with proper font
        let textLayer = CATextLayer()
        textLayer.contentsScale = 3.0  // High resolution for export

        // CRITICAL: Use NSAttributedString instead of plain string for better rendering
        // This fixes issues with CATextLayer text clipping and wrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = config.captionConfig.text.alignment
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedString = NSAttributedString(
            string: item.captionText,
            attributes: [
                .font: config.captionConfig.text.font.withSize(naturalFontSize),
                .foregroundColor: UIColor(cgColor: textCG),
                .paragraphStyle: paragraphStyle
            ]
        )

        textLayer.string = attributedString
        textLayer.isWrapped = true
        textLayer.truncationMode = .none
        textLayer.allowsFontSubpixelQuantization = true
        textLayer.backgroundColor = UIColor.clear.cgColor

        // Calculate text size with wrapping - match VideoPlayer logic for consistency
        let availableWidth = maxWidth - (horizontalPadding * 2)
        let availableHeight = maxHeight - (verticalPadding * 2)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: config.captionConfig.text.font.withSize(naturalFontSize)
        ]

        // Calculate text size using boundingRect (similar to VideoPlayer's sizeThatFits)
        let textSize = (item.captionText as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: availableHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: textAttributes,
            context: nil
        ).size

        // Match VideoPlayer calculation: labelSize = textSize + padding, clamped to max
        let labelWidth = min(textSize.width + (horizontalPadding * 2), maxWidth)
        let labelHeight = min(textSize.height + (verticalPadding * 2), maxHeight)

        // For CATextLayer, use the actual text size (without padding) for the text layer frame
        let textLayerWidth = textSize.width
        let textLayerHeight = textSize.height

        print("📝 Caption '\(item.captionText.prefix(20))...' - textSize: \(textSize), labelSize: (\(labelWidth), \(labelHeight))")

        // Create container layer
        let containerLayer = CALayer()
        containerLayer.contentsScale = 3.0  // High resolution
        containerLayer.frame.size = CGSize(width: labelWidth, height: labelHeight)
        containerLayer.backgroundColor = bgCG
        containerLayer.cornerRadius = cornerRadius
        containerLayer.masksToBounds = true

        // Position text inside container
        textLayer.frame = CGRect(
            x: horizontalPadding,
            y: verticalPadding,
            width: textLayerWidth,
            height: textLayerHeight
        )

        // Add text to container
        containerLayer.addSublayer(textLayer)

        // Position container in video frame with bounds checking
        // CRITICAL: Must match VideoPlayer positioning logic EXACTLY for pixel-perfect match
        // NOTE: AVFoundation uses bottom-left origin (0,0), unlike UIKit which uses top-left
        let finalPosition: CGPoint
        if let px = item.positionX, let py = item.positionY, px >= 0, py >= 0, px <= 1, py <= 1 {
            // Custom position: VideoPlayer stores normalized positions (0-1) relative to video bounds
            // VideoPlayer calculates: centerX = minX + (width * posX), centerY = minY + (height * posY)
            // For export, frame origin is (0,0), so: centerX = width * posX, centerY = height * posY
            // Then convert Y from UIKit (top-left) to AVFoundation (bottom-left) coordinate system
            let centerX = CGFloat(px) * frame.width
            let centerY_UIKit = CGFloat(py) * frame.height
            // Invert Y: UIKit (0=top, 1=bottom) -> AVFoundation (0=bottom, 1=top)
            let centerY = frame.height - centerY_UIKit

            // Clamp position to keep caption within video bounds
            let minX = labelWidth / 2
            let maxX = frame.width - (labelWidth / 2)
            let minY = labelHeight / 2
            let maxY = frame.height - (labelHeight / 2)

            let clampedX = max(minX, min(maxX, centerX))
            let clampedY = max(minY, min(maxY, centerY))

            finalPosition = CGPoint(x: clampedX, y: clampedY)

            if clampedX != centerX || clampedY != centerY {
                print("⚠️ Caption position clamped from (\(centerX), \(centerY)) to (\(clampedX), \(clampedY))")
            }
        } else {
            // Default: bottom center with 10% offset from bottom (match VideoPlayer line 202-203)
            // VideoPlayer: centerY = maxY - bottomOffset - (height/2)
            // AVFoundation: centerY = bottomOffset + (height/2) from bottom
            let bottomOffset = frame.height * 0.1
            finalPosition = CGPoint(x: frame.width / 2, y: bottomOffset + (labelHeight / 2))
        }
        containerLayer.position = finalPosition

        // CRITICAL: CALayer timing in AVVideoCompositionCoreAnimationTool
        // Setting beginTime and duration alone doesn't make layers appear/disappear.
        // We must use explicit opacity animations to control visibility timing.

        let startTime = item.startPoint.toSeconds
        let endTime = item.endPoint.toSeconds
        let captionDuration = endTime - startTime

        // Create opacity animation to control when caption is visible
        // Animation MUST span the entire video duration for proper timing
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.duration = videoDuration  // CRITICAL: Use full video duration, not endTime
        opacityAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        opacityAnimation.fillMode = .both
        opacityAnimation.isRemovedOnCompletion = false

        // Calculate normalized times for keyframes (0.0 to 1.0 across full video)
        let startNormalized = startTime / videoDuration
        let endNormalized = endTime / videoDuration
        let epsilon = 0.0001  // Small offset for crisp transitions

        // Build keyframes: invisible, then visible during caption duration, then invisible again
        var keyTimes: [NSNumber] = [0.0]  // Start of video: invisible
        var values: [CGFloat] = [0.0]

        // Just before caption starts
        if startTime > epsilon {
            keyTimes.append(NSNumber(value: max(0, startNormalized - epsilon)))
            values.append(0.0)
        }

        // Caption appears
        keyTimes.append(NSNumber(value: startNormalized))
        values.append(1.0)

        // Caption stays visible
        keyTimes.append(NSNumber(value: endNormalized))
        values.append(1.0)

        // Caption disappears
        if endTime < videoDuration - epsilon {
            keyTimes.append(NSNumber(value: min(1.0, endNormalized + epsilon)))
            values.append(0.0)
        }

        // End of video: invisible
        if keyTimes.last?.doubleValue ?? 0 < 1.0 {
            keyTimes.append(1.0)
            values.append(0.0)
        }

        opacityAnimation.keyTimes = keyTimes
        opacityAnimation.values = values

        print("📝 Caption timing: start=\(startTime)s, end=\(endTime)s, videoDuration=\(videoDuration)s")
        print("   Keyframes: \(keyTimes.map { $0.doubleValue })")

        containerLayer.add(opacityAnimation, forKey: "opacity")

        return containerLayer
    }
    
    func textAlignment(from config: NSTextAlignment) -> CATextLayerAlignmentMode {
        switch config {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        case .justified:
            return .justified
        case .natural:
            return .natural
        @unknown default:
            return .center
        }
    }
    
    func calculateAbsoluteFontSize(videoSize: CGSize, referenceFontSize: CGFloat) -> CGFloat {
        let divider = videoSize.width > videoSize.height ? videoSize.width : videoSize.height
        let scaleFactor = divider / (playerConfig.videoRect.width > playerConfig.videoRect.height ? playerConfig.videoRect.width : playerConfig.videoRect.height)
        return referenceFontSize * scaleFactor
    }
    
    func exportVideo(onComplete: @escaping (URL?) -> Void) {
        Task {
            composition = AVMutableComposition()
            videoComposition = AVMutableVideoComposition()
            guard let asset = asset,
                  let videoComposition = videoComposition,
                  let composition = composition,
                  let compositionTrack = composition.addMutableTrack(withMediaType: .video,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid),
                  let assetTrack = try await asset.loadTracks(withMediaType: .video).first else {
                onComplete(nil)
                return
            }
            let timeRange = try await CMTimeRange(start: .zero, duration: asset.load(.duration))
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            if let audioAssetTrack = try await asset.loadTracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: audioAssetTrack,
                    at: .zero)
            }
            compositionTrack.preferredTransform = try await assetTrack.load(.preferredTransform)
            
            let videoInfo = try await orientation(from: assetTrack.load(.preferredTransform))
            let videoSize: CGSize
            let naturalSize = try await assetTrack.load(.naturalSize)
            if videoInfo.isPortrait {
                videoSize = CGSize(width: naturalSize.height,
                                   height: naturalSize.width)
            } else {
              videoSize = naturalSize
            }

            // Debug logging to verify resolution
            print("🎬 Export Debug:")
            print("  - Natural size: \(naturalSize)")
            print("  - Is portrait: \(videoInfo.isPortrait)")
            print("  - Final video size (renderSize): \(videoSize)")

            let vSize = videoSize
            let naturalFontSize = calculateAbsoluteFontSize(videoSize: vSize, referenceFontSize: config.captionConfig.text.fontSize)

            // Get video duration for caption timing
            let videoDuration = try await asset.load(.duration).seconds

            let videoLayer = CALayer()
            videoLayer.frame = CGRect(origin: .zero, size: videoSize)
            let outputLayer = CALayer()
            outputLayer.frame = CGRect(origin: .zero, size: videoSize)
            for item in config.items {
                let captionLayer = newCaptionTextLayerWith(item, frame: videoLayer.frame, naturalFontSize: naturalFontSize, videoDuration: videoDuration)
                videoLayer.addSublayer(captionLayer)
            }
            
            outputLayer.addSublayer(videoLayer)
            videoComposition.renderSize = videoSize
            videoComposition.frameDuration =  CMTime(value: 1, timescale: CMTimeScale(try await compositionTrack.load(.nominalFrameRate)))
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
              postProcessingAsVideoLayer: videoLayer,
              in: outputLayer)

            // Verify composition track size
            print("🎬 Composition track size: \(compositionTrack.naturalSize)")
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(
                start: .zero,
                duration: composition.duration)
            videoComposition.instructions = [instruction]
            let layerInstruction = await compositionLayerInstruction(
              for: compositionTrack,
              assetTrack: assetTrack)
            instruction.layerInstructions = [layerInstruction]
            
            let videoName = UUID().uuidString
            let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(videoName)
                .appendingPathExtension("mov")
            await startExporting(with: exportURL, asset: asset, onComplete: onComplete)
        }
    }
    
    private func startExporting(with exportURL: URL, asset: AVAsset, onComplete: @escaping (URL?) -> Void) async {
        // CRITICAL: Use a preset that preserves original resolution
        // Most presets downscale, but these preserve original size:
        // - AVAssetExportPresetPassthrough (no re-encoding, but can't add overlays)
        // - AVAssetExportPreset3840x2160 / 1920x1080 (limited to specific sizes)
        // - Better: Get original track settings and apply to export

        // Get original video track to check resolution and codec
        guard let videoComposition = videoComposition,
              let assetTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let naturalSize = try? await assetTrack.load(.naturalSize) else {
            onComplete(nil)
            return
        }

        // Get original bitrate and codec to understand source quality
        let originalBitrate = try? await assetTrack.load(.estimatedDataRate)
        let formatDescriptions = try? await assetTrack.load(.formatDescriptions)
        print("🎬 Original video info:")
        print("  - Bitrate: \(originalBitrate ?? 0) bps (\(Int((originalBitrate ?? 0) / 1_000_000)) Mbps)")
        print("  - Format descriptions: \(formatDescriptions?.count ?? 0)")

        // CRITICAL: AVAssetExportSession presets have fixed bitrates.
        // Testing different presets to find best quality:
        // - AVAssetExportPresetHEVCHighestQuality: HEVC codec, good compression but may reduce quality
        // - AVAssetExportPresetHighestQuality: H.264 codec, less compression, better quality
        // - AVAssetExportPreset3840x2160: Fixed resolution preset with high bitrate
        //
        // Strategy: Use AVAssetExportPresetHighestQuality (H.264) instead of HEVC
        // because H.264 "Highest Quality" preset typically uses a higher bitrate than HEVC,
        // resulting in better visual quality at the cost of larger file size.

        let outputFileType: AVFileType = .mov

        // Determine best preset based on resolution
        let maxDimension = max(naturalSize.width, naturalSize.height)
        var exportPreset: String

        if maxDimension <= 1920 {
            // For 1080p and below, use the numbered preset for maximum bitrate
            exportPreset = AVAssetExportPreset1920x1080
            print("🎬 Using 1920x1080 preset for high bitrate")
        } else if maxDimension <= 3840 {
            // For up to 4K, use 4K preset
            exportPreset = AVAssetExportPreset3840x2160
            print("🎬 Using 3840x2160 preset for high bitrate")
        } else {
            // Fallback to highest quality
            exportPreset = AVAssetExportPresetHighestQuality
            print("🎬 Using Highest Quality preset")
        }

        // Select preset based on platform
        let finalPreset: String
        if isSimulator {
            finalPreset = AVAssetExportPresetPassthrough
            print("🎬 Using Passthrough (simulator)")
        } else {
            finalPreset = exportPreset
        }

        guard await AVAssetExportSession.compatibility(ofExportPreset: finalPreset, with: asset, outputFileType: outputFileType),
              let exportSession = AVAssetExportSession(asset: composition!, presetName: finalPreset) else {
            onComplete(nil)
            return
        }

        self.exportSession = exportSession
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = exportURL

        // CRITICAL QUALITY SETTINGS:
        exportSession.shouldOptimizeForNetworkUse = false  // Don't compress for streaming
        exportSession.canPerformMultiplePassesOverSourceMediaData = true  // Enable 2-pass encoding for better quality

        // Try to preserve original quality by setting metadata
        if #available(iOS 18.0, *) {
            // On iOS 18+, we could potentially set custom encoder settings
            // but for now, rely on HEVCHighestQuality preset
        }

        // Debug logging
        print("🎬 Export Session Debug:")
        print("  - Preset: \(finalPreset)")
        print("  - Render size: \(videoComposition.renderSize)")
        print("  - Asset natural size: \(naturalSize)")

        await exportSession.export()
        switch exportSession.status {
        case .completed:
            let outputURL = exportSession.outputURL

            // Debug: Check actual exported video resolution and quality
            if let outputURL = outputURL,
               let exportedAsset = AVAsset(url: outputURL) as AVAsset?,
               let exportedTrack = try? await exportedAsset.loadTracks(withMediaType: .video).first,
               let exportedSize = try? await exportedTrack.load(.naturalSize),
               let exportedBitrate = try? await exportedTrack.load(.estimatedDataRate) {
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0
                print("🎬 Export Complete:")
                print("  - Exported video size: \(exportedSize)")
                print("  - Exported bitrate: \(exportedBitrate) bps (\(Int(exportedBitrate / 1_000_000)) Mbps)")
                print("  - File size: \(fileSize) bytes (\(fileSize / 1_000_000) MB)")
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
            }) { saved, error in
                onComplete(saved ? outputURL : nil)
            }
        case .failed:
            print("🎬 Export Failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
            onComplete(nil)
        default:
            print("🎬 Export status: \(exportSession.status.rawValue)")
            onComplete(nil)
        }
    }
    
    private func startExportingWithFallback(with exportURL: URL, asset: AVAsset, onComplete: @escaping (URL?) -> Void) async {
        let exportPreset = AVAssetExportPresetHighestQuality
        let outputFileType: AVFileType = .mov

        guard await AVAssetExportSession.compatibility(ofExportPreset: exportPreset, with: asset, outputFileType: outputFileType),
              let videoComposition = videoComposition,
              let exportSession = AVAssetExportSession(asset: composition!, presetName: exportPreset) else {
            onComplete(nil)
            return
        }

        self.exportSession = exportSession
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = exportURL
        exportSession.shouldOptimizeForNetworkUse = false
        exportSession.canPerformMultiplePassesOverSourceMediaData = true

        await exportSession.export()
        switch exportSession.status {
        case .completed:
            let outputURL = exportSession.outputURL
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
            }) { saved, error in
                onComplete(saved ? outputURL : nil)
            }
        default:
            onComplete(nil)
        }
    }

    func cancelExporting() {
        exportSession?.cancelExport()
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
      var assetOrientation = UIImage.Orientation.up
      var isPortrait = false
      if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
        assetOrientation = .right
        isPortrait = true
      } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
        assetOrientation = .left
        isPortrait = true
      } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
        assetOrientation = .up
      } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
        assetOrientation = .down
      }
      return (assetOrientation, isPortrait)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) async -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        do {
            let transform = try await assetTrack.load(.preferredTransform)
            instruction.setTransform(transform, at: .zero)
        } catch {
            print(error.localizedDescription)
        }
        return instruction
    }
}
