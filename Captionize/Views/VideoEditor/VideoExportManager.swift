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
    
    func newCaptionTextLayerWith(_ item: CaptionItem, frame: CGRect, naturalFontSize: CGFloat) -> CALayer {
        let textLabel = UILabel()
        textLabel.numberOfLines = 10
        textLabel.text = item.captionText
        textLabel.font = config.captionConfig.text.font.withSize(naturalFontSize)
        textLabel.textAlignment = config.captionConfig.text.alignment
        textLabel.frame.size.width = frame.width.percentageWith(percent: 80)
        textLabel.sizeToFit()
        
        let textLayer = CATextLayer()
        textLayer.frame.size = textLabel.frame.size
        textLayer.frame.origin = CGPoint(x: frame.midX - textLayer.frame.width / 2,
                                         y: frame.height.percentageWith(percent: 20) / 4)
        textLayer.isWrapped = true
        textLayer.allowsFontSubpixelQuantization = true
        textLayer.string = item.captionText
        textLayer.beginTime = item.startPoint.toSeconds
        textLayer.duration = item.endPoint.toSeconds - item.startPoint.toSeconds
        textLayer.font = config.captionConfig.text.font
        textLayer.fontSize = naturalFontSize
        textLayer.alignmentMode = textAlignment(from: config.captionConfig.text.alignment)
        textLayer.backgroundColor = config.captionConfig.background.color
        textLayer.foregroundColor = config.captionConfig.text.color
        textLayer.display()
        return textLayer
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
            let vSize = videoSize
            let naturalFontSize = calculateAbsoluteFontSize(videoSize: vSize, referenceFontSize: config.captionConfig.text.fontSize)
            
            let videoLayer = CALayer()
            videoLayer.frame = CGRect(origin: .zero, size: videoSize)
            let outputLayer = CALayer()
            outputLayer.frame = CGRect(origin: .zero, size: videoSize)
            for item in config.items {
                let captionLayer = newCaptionTextLayerWith(item, frame: videoLayer.frame, naturalFontSize: naturalFontSize)
                videoLayer.addSublayer(captionLayer)
            }
            
            outputLayer.addSublayer(videoLayer)
            videoComposition.renderSize = videoSize
            videoComposition.frameDuration =  CMTime(value: 1, timescale: CMTimeScale(try await compositionTrack.load(.nominalFrameRate)))
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
              postProcessingAsVideoLayer: videoLayer,
              in: outputLayer)
            
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
        guard await AVAssetExportSession.compatibility(ofExportPreset: AVAssetExportPresetHighestQuality,
                                                       with: asset,
                                                       outputFileType: .mov) else {
            onComplete(nil)
            return
        }
        guard let videoComposition = videoComposition,
              let exportSession = AVAssetExportSession(asset: composition!,
                                                       presetName: isSimulator ? AVAssetExportPresetPassthrough : AVAssetExportPresetHighestQuality) else {
            onComplete(nil)
            return
        }
        self.exportSession = exportSession
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mov
        exportSession.outputURL = exportURL
        await exportSession.export()
        switch exportSession.status {
        case .completed:
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
            }) { saved, error in
                if saved {
                    onComplete(exportSession.outputURL)
                } else {
                    onComplete(nil)
                }
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
