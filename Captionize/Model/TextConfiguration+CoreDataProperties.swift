//
//  TextConfiguration+CoreDataProperties.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 26.05.23.
//
//

import Foundation
import CoreData


extension TextConfiguration {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextConfiguration> {
        return NSFetchRequest<TextConfiguration>(entityName: "TextConfiguration")
    }

    @NSManaged public var alignment: Int32
    @NSManaged public var color: String?
    @NSManaged public var fontName: String?
    @NSManaged public var fontSize: Double
    @NSManaged public var myProject: MyProject?

}

extension TextConfiguration : Identifiable {

}
