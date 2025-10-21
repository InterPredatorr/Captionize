//
//  CaptionItem.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 01.05.23.
//

import SwiftUI

enum CaptionButtonSide: Codable {
    case left
    case right
    case undefined
}

struct CaptionItem: Identifiable, Equatable, Hashable {
    var id = UUID()
    var isChanging = false
    var captionText: String
    var startPoint: Double
    var endPoint: Double
    var side: CaptionButtonSide = .undefined
    // New per-caption colors (stored as hex strings for hashable conformance)
    var textColorHex: String? = nil
    var backgroundColorHex: String? = nil
    // Normalized center position within the video frame (0.0...1.0). Nil = use default bottom placement.
    var positionX: Double? = nil
    var positionY: Double? = nil
    var width: Double {
        get {
            if endPoint - startPoint < Constants.VECap.minWidth {
                return Constants.VECap.minWidth
            } else {
                return endPoint - startPoint
            }
        }
    }
}
