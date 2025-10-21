//
//  Persistence.swift
//  Captionize
//
//  Created by Sevak Tadevosyan on 24.04.23.
//

import Foundation
import CoreData

class MyProjectsProvider: ObservableObject {
    
    static let shared = MyProjectsProvider()

    let persistentContainer = NSPersistentContainer(name: "Projects")
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var newContext: NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    private init() {
        if let description = persistentContainer.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        self.persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func exisits(_ project: MyProject, in context: NSManagedObjectContext) -> MyProject? {
        try? context.existingObject(with: project.objectID) as? MyProject
    }
    func delete(_ project: MyProject, in context: NSManagedObjectContext) throws {
        if let existingProject = exisits(project, in: context) {
            context.delete(existingProject)
            Task(priority: .background) {
                try await context.perform {
                    try context.save()
                }
            }
        }
    }
    
    func persist(in context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
