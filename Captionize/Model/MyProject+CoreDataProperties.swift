//
//  MyProject+CoreDataProperties.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 26.05.23.
//
//

import Foundation
import CoreData


extension MyProject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyProject> {
        return NSFetchRequest<MyProject>(entityName: "MyProject")
    }

    @NSManaged public var assetId: String?
    @NSManaged public var captions: NSSet?
    @NSManaged public var textConfig: TextConfiguration?
    @NSManaged public var backgroundConfig: BackgroundConfiguration?
    @NSManaged public var activeTextConfig: ActiveTextConfiguration?

}

// MARK: Generated accessors for captions
extension MyProject {

    @objc(addCaptionsObject:)
    @NSManaged public func addToCaptions(_ value: Caption)

    @objc(removeCaptionsObject:)
    @NSManaged public func removeFromCaptions(_ value: Caption)

    @objc(addCaptions:)
    @NSManaged public func addToCaptions(_ values: NSSet)

    @objc(removeCaptions:)
    @NSManaged public func removeFromCaptions(_ values: NSSet)

}

extension MyProject : Identifiable {

}
