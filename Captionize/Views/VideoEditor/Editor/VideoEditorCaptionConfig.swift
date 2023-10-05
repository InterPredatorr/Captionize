//
//  VideoEditorCaptionConfig.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 24.05.23.
//

import UIKit
import SwiftUI

struct VideoEditorCaptionConfig {
    var text: VideoEditorCaptionTextConfig
    var background: VideoEditorCaptionBackgroundConfig
    var activeWord: VideoEditorCaptionActiveWordConfig
}

struct VideoEditorCaptionTextConfig {
    var font: UIFont
    var fontSize: CGFloat
    var color: CGColor
    var alignment: NSTextAlignment
}

struct VideoEditorCaptionBackgroundConfig {
    var color: CGColor
}

struct VideoEditorCaptionActiveWordConfig {
    var font: UIFont
    var fontSize: CGFloat
    var color: CGColor
}
