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
}

struct VideoEditorCaptionTextConfig {
    var font: UIFont
    var fontSize: CGFloat
    var alignment: NSTextAlignment
}

