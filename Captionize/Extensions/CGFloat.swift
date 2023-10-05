//
//  CGFloat + Extensions.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 01.05.23.
//

import Foundation

extension CGFloat {
    var unsigned: CGFloat {
        return self >= 0.0 ? self : 0.0
    }
    func percentageWith(percent: CGFloat) -> CGFloat {
        return self * percent / 100.0
    }
}
