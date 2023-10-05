//
//  BackgroundConfiguration+CoreDataProperties.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 26.05.23.
//
//

import Foundation
import CoreData


extension BackgroundConfiguration {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BackgroundConfiguration> {
        return NSFetchRequest<BackgroundConfiguration>(entityName: "BackgroundConfiguration")
    }

    @NSManaged public var color: String?
    @NSManaged public var myProject: MyProject?

}

extension BackgroundConfiguration : Identifiable {

}
