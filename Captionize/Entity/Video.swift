//
//  Video.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation
import PhotosUI

struct Video {
    var thumbnail: UIImage?
    var duration: String?
    let asset: PHAsset
}

extension Video: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.asset)
    }
}
