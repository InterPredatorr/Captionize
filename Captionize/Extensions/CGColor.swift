//
//  CGColor.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 25.05.23.
//

import UIKit

extension CGColor {
    func toHexString() -> String? {
        guard let components = self.components, components.count > 3 else {
            return nil
        }
        
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components[3]
        
        let redInt = Int(red * 255)
        let greenInt = Int(green * 255)
        let blueInt = Int(blue * 255)
        let alphaInt = Int(alpha * 255)
        
        let hexString = String(format: "#%02X%02X%02X%02X", alphaInt, redInt, greenInt, blueInt)
        return hexString
    }
    
    static func fromHexString(_ hexString: String?) -> CGColor? {
        guard let hexString = hexString?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        
        var sanitizedString = hexString
        if sanitizedString.hasPrefix("#") {
            sanitizedString = String(sanitizedString.dropFirst())
        }
        
        guard sanitizedString.count == 6 || sanitizedString.count == 8 else {
            return nil
        }
        
        var rgbValue: Int64 = 0
        Scanner(string: sanitizedString).scanHexInt64(&rgbValue)
        
        var alpha: CGFloat = 1.0
        if sanitizedString.count == 8 {
            let alphaValue = (rgbValue & 0xFF000000) >> 24
            alpha = CGFloat(alphaValue) / 255.0
        }
        
        let redValue = (rgbValue & 0xFF0000) >> 16
        let greenValue = (rgbValue & 0x00FF00) >> 8
        let blueValue = rgbValue & 0x0000FF
        
        let red = CGFloat(redValue) / 255.0
        let green = CGFloat(greenValue) / 255.0
        let blue = CGFloat(blueValue) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
    }
}

