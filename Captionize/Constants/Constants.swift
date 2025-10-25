//
//  Constants.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 23.04.23.
//

import UIKit
import CoreMedia

struct Constants {
    static let videoEditorConfigViewPercentage = 35.0
    static let videoEditorHeight = 135.0
    static var videoEditorTimerHeight = 30.0
    struct VECap { // Video Editor Caption
        static let minWidth = secondToPoint / 2
        static let minWidthWithSpacing = minWidth + spacing
        static let secondToPoint = 124.0
        static let spacing = 1.0
        static let height = 80.0
        static let radius = 12.0
        static let buttonWidth = 15.0
        static let buttonPadding = 4.0
        static let textLineLimit = 3
    }
    struct VPCap { // Video Player Caption
        static let captionPadding = 30.0
        static let captionheight = 50.0
        // High timescale for precise seeks/exports
        static let timescale: CMTimeScale = 40000
        // UI tick frequency for playhead updates (throttles scroll/availability checks)
        static let uiTickPerSecond: CMTimeScale = 15
    }
    struct VETextSettings {
        static let cellCornerRadius = 16.0
        static var cellHeight = UIScreen.screenHeight.percentageWith(percent: 35) / 5
        static let constantSizedCellWidth = 90.0
        static let itemsSpacing = UIScreen.screenHeight.percentageWith(percent: 35) / 20
    }
    struct Colors {
        static let black = UIColor.black.cgColor.copy(alpha: 0.4)!
        static let white = UIColor.white.cgColor
    }
}
