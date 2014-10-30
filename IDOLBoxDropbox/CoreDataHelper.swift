//
//  CoreDataHelper.swift
//  IDOLBox
//
//  Created by TwoPi on 28/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

class CoreDataHelper: NSObject {
    
    class var sharedInstance : CoreDataHelper {
        struct Singleton {
            static let instance = CoreDataHelper()
        }
        return Singleton.instance
    }
   
    // Core Data methods
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.twopi.IDOLBox" in the application's documents Application Support directory.
        let url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(Constants.GroupContainerName)
        return url as NSURL!
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let bundle = NSBundle(identifier: "com.twopi.IDOLBox")
        let modelURL = bundle?.URLForResource("Dropbox", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("IDOLBoxDropbox.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        var options = [NSMigratePersistentStoresAutomaticallyOption : NSNumber(bool: true),
                       NSInferMappingModelAutomaticallyOption       : NSNumber(bool: true)]
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "IDOLBoxDropbox", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    // Use this to obtain the managed object context
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()

    func commit () {
        if let moc = self.managedObjectContext {
            
            if moc.hasChanges {
                var error: NSError? = nil
                if !moc.save(&error) {
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                }
            }
        }
    }

    func rollback () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                moc.rollback()
            }
        }
    }
}
