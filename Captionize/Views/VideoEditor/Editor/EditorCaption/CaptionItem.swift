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
