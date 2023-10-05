//
//  ActiveTextConfiguration+CoreDataProperties.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 26.05.23.
//
//

import Foundation
import CoreData


extension ActiveTextConfiguration {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActiveTextConfiguration> {
        return NSFetchRequest<ActiveTextConfiguration>(entityName: "ActiveTextConfiguration")
    }

    @NSManaged public var color: String?
    @NSManaged public var fontName: String?
    @NSManaged public var fontSize: Double
    @NSManaged public var myProject: MyProject?

}

extension ActiveTextConfiguration : Identifiable {

}
