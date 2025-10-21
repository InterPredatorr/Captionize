//
//  VideoEditorViewModel.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 18.04.23.
//

import SwiftUI
import Combine
import AVKit
import PhotosUI
import UIKit

enum Editor: String, CaseIterable {
    case text = "Text"
    case resync = "Captions"
}

class VideoEditorViewModel: ObservableObject {
    
    // Sheet presentation state for editing a caption
    @Published var isShowingCaptionSheet: Bool = false
    @Published var selectedCaptionId: UUID? = nil
    
    struct VideoEditorStates {
        var isLoaded = false
        var isPlaying = false
        var isAutoScrolling = false
        var isAbleToAddNewCaption = false
        var isAbleToRemoveCaption = false
    }
    struct VideoPlayerConfig {
        var player = AVPlayer()
        var playerLayer = AVPlayerViewController()
        var asset: AVAsset?
        var currentTime: Double = .zero
        var videoTimeDescription = ""
        var videoDuration: Double = .zero
        var videoRect: CGRect = .zero
        var captionText = ""
    }
    struct CaptionsConfig {
        var items: [CaptionItem]
        var seconds = [String]()
        var selectedEditor: Editor = .resync
        var currentItem: CaptionItem?
        var captionConfig: VideoEditorCaptionConfig
        var colors = [VideoEditorColor]()
    }
    
    let video: Video
    var cancellable: AnyCancellable?
    var timeObserverToken: Any?
    @Published var settings = VideoEditorSettingsProvider.settings
    @Published var editorStates = VideoEditorStates()
    @Published var playerConfig = VideoPlayerConfig()
    @Published var captionsConfig: CaptionsConfig!
    @Published var videoExportManager: VideoExportManager?


    init(video: Video, captionsConfig: CaptionsConfig) {
        self.captionsConfig = captionsConfig
        self.video = video
        fetchPlayer()
    }
    
    deinit {
        removePeriodicTimeObserver()
    }
}

// MARK: - Video Player Configuration
extension VideoEditorViewModel {
    
    private func fetchPlayer() {
        cancellable = requestPlayer(from: video.asset)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Failed to get player: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] asset in
                guard let self else { return }
                self.playerConfig.asset = asset
                videoExportManager = VideoExportManager(config: captionsConfig,
                                                        playerConfig: playerConfig,
                                                        asset: asset)
                createPlayer(from: asset)
                self.cancellable?.cancel()
            })
    }
    
    private func createPlayer(from asset: AVAsset) {
        let item = AVPlayerItem(asset: asset)
        playerConfig.player = AVPlayer(playerItem: item)
        self.setPlayerAudio()
        self.updateProperties(with: playerConfig.player)
        self.setupConfigs()
        addPeriodicObserver()
    }
    
    private func requestPlayer(from asset: PHAsset) -> AnyPublisher<AVAsset, Error> {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        return Future<AVAsset, Error> { promise in
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: options) { asset, _, info in
                guard let info = info, let error = info[PHImageErrorKey] as? Error else {
                    if let asset = asset {
                        promise(.success(asset))
                    }
                    return
                }
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func addPeriodicObserver() {
        let time = CMTime(value: 1, timescale: Constants.VPCap.timescale)
        timeObserverToken = playerConfig.player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            guard let self else { return }
            playerConfig.currentTime = time.seconds
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            playerConfig.player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    private func updateProperties(with player: AVPlayer) {
        self.playerConfig.player = player
        self.playerConfig.videoDuration = player.currentItem?.duration.seconds ?? .zero
        editorStates.isLoaded = true
            captionsConfig.seconds = self.getSecondTexts()
    }

    func changeTextCapitalization() {
        guard let item = (settings.capitalizationTypes.first { $0.isSelected }) else { return }
        
        switch item.type {
        case .none:
            break
        case .AB:
            captionsConfig.items = captionsConfig.items.map { item in
                var tmp = item
                tmp.captionText = tmp.captionText.uppercased()
                return tmp
            }
        case .Ab:
            captionsConfig.items = captionsConfig.items.map({ item in
                var tmp = item
                let words = tmp.captionText.components(separatedBy: " ")
                let capitalizedWords = words.map { $0.prefix(1).capitalized + $0.dropFirst().lowercased() }
                tmp.captionText = capitalizedWords.joined(separator: " ")
                return tmp
            })
        case .ab:
            captionsConfig.items = captionsConfig.items.map { item in
                var tmp = item
                tmp.captionText = tmp.captionText.lowercased()
                return tmp
            }
        }
    }

    
    private func setPlayerAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func seekToPoint(_ value: Double) {
        let fps = Constants.VPCap.timescale
        let valueWithoutOffset = value - (Constants.VECap.secondToPoint / 2)
        let outOfEnd = valueWithoutOffset / Constants.VECap.secondToPoint > playerConfig.videoDuration
        let checkedTime = valueWithoutOffset < 0.0 ? -Double.leastNonzeroMagnitude : outOfEnd ? playerConfig.videoDuration : valueWithoutOffset / Constants.VECap.secondToPoint
            playerConfig.currentTime = checkedTime
        if playerConfig.player.status == .readyToPlay {
            playerConfig.player.seek(to: CMTime(value: CMTimeValue(checkedTime * fps.toDouble), timescale: fps),
                        toleranceBefore: .zero,
                        toleranceAfter: .zero)
            playerConfig.player.pause()
            editorStates.isPlaying = false
        }
    }
    
    func checkDurationText() {
        let zero = 0.formateInSecondsMinute()
        let timeSeconds =  self.editorStates.isLoaded ? playerConfig.currentTime.formateInSecondsMinute() : zero
        self.playerConfig.videoTimeDescription = timeSeconds + " / " + (self.video.duration ?? zero)
    }
}


// MARK: - ViewModel Captions Configuration
extension VideoEditorViewModel {
    
    private func getSecondTexts() -> [String] {
        let seconds = Int(playerConfig.player.currentItem?.duration.seconds ?? 1.0)
        var secondsTexts: [String] = []
        for i in 0...seconds {
            secondsTexts.append(Double(i).formateInSecondsMinute())
        }
        return secondsTexts
    }
    
    func checkCaptionText() {
        var text: String?
            captionsConfig.items.forEach { item in
                if item.startPoint.toSeconds...item.endPoint.toSeconds ~= playerConfig.currentTime + 0.5 {
                text = item.captionText
                return
            }
        }
        playerConfig.captionText = text ?? ""
    }
    
    func checkAvailibility() {
        let halfOfSecond = 0.5
        let minWidth = Constants.VECap.minWidth
        let endOfTime = Double(captionsConfig.seconds.count) * Constants.VECap.secondToPoint
        if captionsConfig.items.isEmpty {
            editorStates.isAbleToAddNewCaption = endOfTime - (playerConfig.currentTime + halfOfSecond).toPoints > minWidth
            editorStates.isAbleToRemoveCaption = false
            return
        }
        for (index, item) in captionsConfig.items.enumerated() {
            if item.startPoint < item.endPoint && item.startPoint...item.endPoint ~= (playerConfig.currentTime + halfOfSecond).toPoints {
                captionsConfig.currentItem = item
                editorStates.isAbleToRemoveCaption = true
                editorStates.isAbleToAddNewCaption = false
                break
            }
            if item.startPoint - (playerConfig.currentTime + halfOfSecond).toPoints > 0 {
                editorStates.isAbleToAddNewCaption = item.startPoint - (playerConfig.currentTime + halfOfSecond).toPoints > minWidth
                editorStates.isAbleToRemoveCaption = false
                break
            }
            if (index == captionsConfig.items.count - 1 && item.endPoint < (playerConfig.currentTime + halfOfSecond).toPoints && endOfTime - (playerConfig.currentTime + halfOfSecond).toPoints > minWidth) {
                editorStates.isAbleToAddNewCaption = true
                editorStates.isAbleToRemoveCaption = false
                break
            } else {
                editorStates.isAbleToAddNewCaption = false
                editorStates.isAbleToRemoveCaption = false
            }
        }
    }
    
    func getPlayerCaptionFrame(from rect: CGRect) -> CGRect {
        let tenPercentOfWidth = rect.width.percentageWith(percent: 10)
        let captionHeight = rect.height.percentageWith(percent: 20)
        return CGRect(x: rect.minX + tenPercentOfWidth,
                      y: rect.maxY - captionHeight - captionHeight / 4,
                      width: rect.width - (2 * tenPercentOfWidth),
                      height: captionHeight)
    }
    
    func getSpacerWidth(at index: Int) -> CGFloat {
        let currectItem = captionsConfig.items[index]
        if index == 0 {
            return currectItem.startPoint.unsigned
        }
        if 1..<captionsConfig.items.count ~= index {
            return (currectItem.startPoint - captionsConfig.items[index - 1].endPoint).unsigned
        }
        return .zero
    }
    
    private func setupConfigs() {
        settings.alignments = settings.alignments.map { alignment in
            var tmp = alignment
            if tmp.alignment == captionsConfig.captionConfig.text.alignment.rawValue {
                tmp.isSelected = true
            }
            return tmp
        }
        settings.fonts = settings.fonts.map { font in
            var tmp = font
            if tmp.font.name == captionsConfig.captionConfig.text.font.fontName {
                tmp.isSelected = true
            }
            return tmp
        }
        settings.textSizeConfig.currentSize = captionsConfig.captionConfig.text.fontSize
        if !captionsConfig.items.isEmpty {
            settings.capitalizationTypes = settings.capitalizationTypes.map({ type in
                var tmp = type
                switch tmp.type {
                case .AB:
                    tmp.isSelected = captionsConfig.items.first!.captionText.isUppercased()
                case .ab:
                    tmp.isSelected = captionsConfig.items.first!.captionText.isLowercased()
                case .Ab:
                    tmp.isSelected = captionsConfig.items.first!.captionText.areFirstLettersUppercased()
                case .none:
                    break
                }
                return tmp
            })
        }
    }

    func udpatePoints(for item: CaptionItem, x: CGFloat) {
        let index = captionsConfig.items.firstIndex(of: item)
        guard let index = index else { return }
        captionsConfig.items[index].isChanging = true
        switch item.side {
        case .left:
            setLeftPoint(x: x, at: index)
        case .right:
            setRightPoint(x: x, at: index)
        case .undefined:
            break
        }
        checkAvailibility()
        checkCaptionText()
    }
    
    private func setLeftPoint(x: CGFloat, at index: Int) {
        let currentItem = captionsConfig.items[index]
        if index > 0 && x < captionsConfig.items[index - 1].endPoint {
            let prev = captionsConfig.items[index - 1]
            if x < prev.startPoint + Constants.VECap.minWidthWithSpacing {
                captionsConfig.items[index].startPoint = prev.endPoint + Constants.VECap.spacing
            } else {
                captionsConfig.items[index].startPoint = x
                captionsConfig.items[index - 1].endPoint = x - Constants.VECap.spacing
            }
        } else {
            let minWidth = currentItem.endPoint - Constants.VECap.minWidth
            captionsConfig.items[index].startPoint = x > minWidth ? minWidth : x.unsigned
        }
    }
    
    private func setRightPoint(x: CGFloat, at index: Int) {
        let currentItem = captionsConfig.items[index]
        let endPoint = Double(captionsConfig.seconds.count) * Constants.VECap.secondToPoint
        if index < captionsConfig.items.count - 1 && x > captionsConfig.items[index + 1].startPoint {
            let next = captionsConfig.items[index + 1]
            if x > next.endPoint - Constants.VECap.minWidthWithSpacing {
                captionsConfig.items[index].endPoint = next.startPoint - Constants.VECap.spacing
            } else {
                captionsConfig.items[index].endPoint = x
                captionsConfig.items[index + 1].startPoint = x + Constants.VECap.spacing
            }
        } else {
            let end = x < endPoint ? x : endPoint
            let minWidth = currentItem.startPoint + Constants.VECap.minWidth
            captionsConfig.items[index].endPoint = x < minWidth ? minWidth : end
        }
    }
    
    func addNewCaption() {
        playerConfig.player.pause()
        editorStates.isPlaying = false
        let newItem = CaptionItem(captionText: "",
                                  startPoint: (playerConfig.currentTime + 0.5).toPoints,
                                  endPoint: (playerConfig.currentTime + 0.5).toPoints + Constants.VECap.minWidth)
        if let index = captionsConfig.items.firstIndex(where: { $0.startPoint > (playerConfig.currentTime + 0.5).toPoints }) {
            captionsConfig.items.insert(newItem, at: index)
        } else if captionsConfig.items.isEmpty || (!captionsConfig.items.isEmpty && playerConfig.currentTime.toPoints > captionsConfig.items.last!.endPoint) {
            captionsConfig.items.append(newItem)
        }
        checkAvailibility()
        checkCaptionText()
    }
    
    func removeCaption() {
        playerConfig.player.pause()
        editorStates.isPlaying = false
        guard let current = captionsConfig.currentItem else { return }
            captionsConfig.items.removeAll { $0 == current }
        checkAvailibility()
        checkCaptionText()
    }
    
    func exportVideo(onComplete: @escaping (URL?) -> Void) {
        videoExportManager = VideoExportManager(config: captionsConfig,
                                                playerConfig: playerConfig,
                                                asset: playerConfig.asset)
        videoExportManager?.exportVideo(onComplete: onComplete)
    }
}
