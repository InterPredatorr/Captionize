//
//  Fonts.swift
//  Captionize
//
//  Created by 2830327inc on 26/03/23.
//

import SwiftUI

extension Font {
    static func roboto(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        
        Roboto.register()
        
        let baseName = Roboto.baseName
        
        // scales font on iPad devices
        let scale: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1
        
        switch weight {
        case .medium:
            return Font.custom(baseName + "Medium", size: size * scale)
        case .bold:
            return Font.custom(baseName + "Bold", size: size * scale)
        case .regular:
            return Font.custom(baseName + "Regular", size: size * scale)
        default:
            fatalError("\(Font.self) \(weight) is not yet supported")
        }
    }
}

extension UIFont {
    static func roboto(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        
        Roboto.register()
        
        let baseName = Roboto.baseName
        
        // scales font on iPad devices
        let scale: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1
        
        switch weight {
        case .medium:
            return UIFont(name: baseName + "Medium", size: size * scale)!
        case .bold:
            return UIFont(name: baseName + "Bold", size: size * scale)!
        case .regular:
            return UIFont(name: baseName + "Regular", size: size * scale)!
        default:
            fatalError("\(UIFont.self) \(weight) is not yet supported")
        }
    }
}

fileprivate enum Roboto {
    
    static var baseName: String = "Roboto-"
    
    static var isRegistered: Bool = false
    
    static func register() {
        if isRegistered {
            return
        }
        
        for path in Self.paths {
            registerFont(path, fileExtension: "ttf")
        }
        
        isRegistered = true
    }
    
    private static let paths = [
        "Roboto-Medium",
        "Roboto-Bold",
        "Roboto-Regular"
    ]
    
    private static func registerFont(_ name: String, fileExtension: String) {
        
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            print("No font named \(name).\(fileExtension) was found in the module bundle")
            return
        }
        
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
        print(error ?? "Successfully registered font: \(name)")
    }
}
