//
//  VideoEditorSettings.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 21.05.23.
//

import UIKit
import SwiftUI

struct VideoEditorSettingsModel: Decodable {
    let settings: VideoEditorSettings
}

struct VideoEditorSettings: Decodable {
    var customFont: VideoEditorFont
    var fonts: [VideoEditorFont]
    var alignments: [VideoEditorAlignment]
    var capitalizationTypes: [CapitalizationType]
    var textSizeConfig: VideoEditorTextSizeConfig
}

struct VideoEditorFont: Decodable, Identifiable {
    var id: UUID
    let name: String
    let font: FontInfo
    var isSelected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, font, isSelected
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        font = try container.decode(FontInfo.self, forKey: .font)
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? false

        if let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
    }
}

struct FontInfo: Decodable {
    let name: String
    let size: Double
}

struct RGBAColor: Decodable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

struct VideoEditorColor: Decodable, Equatable, Identifiable {
    var id: UUID
    var color: CGColor
    let name: String
    let type: ColorType
    
    enum CodingKeys: String, CodingKey {
        case id, color, name, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rgbaColor = try container.decode(RGBAColor.self, forKey: .color)
        color = CGColor(red: rgbaColor.red, green: rgbaColor.green, blue: rgbaColor.blue, alpha: rgbaColor.alpha)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ColorType.self, forKey: .type)
        if let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
    }
}

enum ColorType: String, Decodable {
    case text
    case background
    case activeWord
}

struct VideoEditorAlignment: Decodable, Identifiable {
    var id: UUID
    let iconName: String
    let alignment: Int
    var isSelected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, iconName, alignment, isSelected
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iconName = try container.decode(String.self, forKey: .iconName)
        alignment = try container.decode(Int.self, forKey: .alignment)
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? false
        if let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
    }
}

struct CapitalizationType: Decodable, Identifiable {
    var id: UUID
    let type: CapitalizationTypes
    var isSelected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, type, isSelected
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CapitalizationTypes.self, forKey: .type)
        isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? false
        if let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
    }
}

enum CapitalizationTypes: String, Decodable {
    case none = "--"
    case ab
    case Ab
    case AB
}

struct VideoEditorTextSizeConfig: Decodable {
    var currentSize: Double
    let maxSize: Double
    let minSize: Double
}

struct VideoEditorSettingsProvider {
    static let settings = VideoEditorSettingsProvider.fetchSettings()!
    private init() {}
    
    static private func fetchSettings() -> VideoEditorSettings? {
        let decoder = JSONDecoder()

        let settingsFilePath = Bundle.main.path(forResource: "video_editor_settings", ofType: "json")!
        do {
            let data = try Data(contentsOf: URL(filePath: settingsFilePath))
            let result = try decoder.decode(VideoEditorSettingsModel.self, from: data)
            return result.settings
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}
