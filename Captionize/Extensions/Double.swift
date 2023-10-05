//
//  Extensions.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 22.04.23.
//

import AVFoundation

extension Double {
    
    var unsigned: Double {
        return self >= 0.0 ? self : 0.0
    }
    
    var toSeconds: Double {
        return self / Constants.VECap.secondToPoint
    }
    var toPoints: Double {
        return self * Constants.VECap.secondToPoint
    }
    
    func percentageWith(percent: Double) -> Double {
        return self * percent / 100.0
    }
}


