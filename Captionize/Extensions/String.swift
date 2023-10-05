//
//  String.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 28.05.23.
//

import Foundation


extension String {
    func isLowercased() -> Bool {
        for char in self {
            if char == " " { continue }
            if !char.isLowercase { return false }
        }
        return true
    }
    
    func isUppercased() -> Bool {
        for char in self {
            if char == " " { continue }
            if !char.isUppercase { return false }
        }
        return true
    }
    
    func areFirstLettersUppercased() -> Bool {
        let words = self.components(separatedBy: " ")
        return words.allSatisfy { word in
            guard let firstChar = word.first else {
                return false
            }
            return firstChar.isUppercase && word.dropFirst().allSatisfy { $0.isLowercase }
        }
    }
}
