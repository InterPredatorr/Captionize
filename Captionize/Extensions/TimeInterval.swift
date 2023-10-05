//
//  TimeInterval.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import Foundation

extension TimeInterval {
    func formateInSecondsMinute() -> String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
