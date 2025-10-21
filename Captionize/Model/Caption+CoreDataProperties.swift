//
//  Caption+CoreDataProperties.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 26.05.23.
//
//

import Foundation
import CoreData


extension Caption {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Caption> {
        return NSFetchRequest<Caption>(entityName: "Caption")
    }

    @NSManaged public var captionText: String?
    @NSManaged public var endPoint: Double
    @NSManaged public var textColor: String?
    @NSManaged public var backgroundColor: String?
    @NSManaged public var startPoint: Double
    @NSManaged public var positionX: Double
    @NSManaged public var positionY: Double
    @NSManaged public var myProject: MyProject?

}

extension Caption : Identifiable {

}
