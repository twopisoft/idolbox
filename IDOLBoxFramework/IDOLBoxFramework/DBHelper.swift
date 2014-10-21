//
//  DBHelper.swift
//  IDOLMenubar
//
//  Created by TwoPi on 20/9/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

// Central class for carrying out Core Data operations
// Only provides class level ops

public class DBHelper {
    
    public class var sharedInstance : DBHelper {
        struct Singleton {
            static let instance = DBHelper()
        }
        return Singleton.instance
    }
    
    // MARK: Data handlers for index information
    
    // Update index data. This involves:
    // 1. From the data coming in from List Index service, find what indexes are updated
    // 2. And which of the indexes have been deleted
    // 3. Finally, add the new index entries
    public class func updateIndexes(managedObjectContext : NSManagedObjectContext, data : [TypeAliases.IndexTuple]) -> NSError? {
        var foundObjs :[Int:TypeAliases.IndexTuple] = [:]
        
        var freq = NSFetchRequest(entityName: "IdolIndex")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil) as? [IdolIndex]
        
        for mo in res! {
            var found = false
            for (i,entry) in enumerate(data) {
                let (indexName,indexFlavor,isPublic,indexInfo,indexType) = entry
                
                // First update existing indexes info
                if mo.name == indexName {
                    found = true
                    mo.setValue(indexFlavor, forKey: "flavor")
                    mo.setValue(isPublic, forKey: "isPublic")
                    mo.setValue(indexInfo, forKey: "info")
                    mo.setValue(indexType, forKey: "type")
                    foundObjs[i]=entry
                }
            }
            
            // Delete the ones, that no longer exist on the server
            if !found {
                managedObjectContext.deleteObject(mo as NSManagedObject)
            }
        }
        
        // Finally, add the new index entries
        var newData : [TypeAliases.IndexTuple] = []
        for (i,entry) in enumerate(data) {
            if foundObjs[i] == nil {
                newData.append(entry)
            }
        }
        
        for newEntry in newData {
            let (indexName,indexFlavor,isPublic,indexInfo,indexType) = newEntry
            let obj = IdolIndex(entity: NSEntityDescription.entityForName("IdolIndex", inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
            obj.setValue(indexName, forKey: "name")
            obj.setValue(indexFlavor, forKey: "flavor")
            obj.setValue(isPublic, forKey: "isPublic")
            obj.setValue(indexInfo, forKey: "info")
            obj.setValue(indexType, forKey: "type")
        }
        
        return nil
    }
    
    // Update box entry data similar in logic to updateIndexes.
    public class func updateBoxEntries(managedObjectContext : NSManagedObjectContext, data : [TypeAliases.ResultTuple]) -> NSError? {
        var foundObjs :[Int:TypeAliases.ResultTuple] = [:]
        
        var freq = NSFetchRequest(entityName: "IdolBoxEntry")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil) as? [IdolBoxEntry]
        
        for mo in res! {
            var found = false
            for (i,entry) in enumerate(data) {
                let (title,reference,_,index,moddate,summary,content) = entry
                
                // First update existing indexes info
                if mo.reference == reference && mo.index == index {
                    found = true
                    mo.setValue(title, forKey: "title")
                    mo.setValue(moddate, forKey: "moddate")
                    mo.setValue(summary, forKey: "summary")
                    mo.setValue(content, forKey: "content")
                    foundObjs[i]=entry
                }
            }
            
            // Delete the ones, that no longer exist on the server
            if !found {
                managedObjectContext.deleteObject(mo as NSManagedObject)
            }
        }
        
        // Finally, add the new index entries
        var newData : [TypeAliases.ResultTuple] = []
        for (i,entry) in enumerate(data) {
            if foundObjs[i] == nil {
                newData.append(entry)
            }
        }
        
        for newEntry in newData {
            let (title,reference,_,index,moddate,summary,content) = newEntry
            let obj = IdolIndex(entity: NSEntityDescription.entityForName("IdolBoxEntry", inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
            obj.setValue(title, forKey: "title")
            obj.setValue(reference, forKey: "reference")
            obj.setValue(index, forKey: "index")
            obj.setValue(moddate, forKey: "moddate")
            obj.setValue(summary, forKey: "summary")
            obj.setValue(content, forKey: "content")
        }
        
        return nil
    }
    
    // Store information about documents in the index
    public class func storeBoxEntries(managedObjectContext : NSManagedObjectContext, searchResults : [TypeAliases.ResultTuple]) -> NSError? {
        for result in searchResults {
            let (title,reference,weight,index,moddate,summary,content) = result
            let obj = IdolSearchResult(entity: NSEntityDescription.entityForName("IdolBoxEntry", inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
            obj.setValue(title, forKeyPath: "title")
            obj.setValue(reference, forKeyPath: "reference")
            obj.setValue(index, forKeyPath: "index")
            obj.setValue(moddate, forKeyPath: "moddate")
            obj.setValue(summary, forKeyPath: "summary")
            obj.setValue(content, forKeyPath: "content")
        }
        
        return nil
    }
    
    // Store information about search results
    public class func storeSearchResults(managedObjectContext : NSManagedObjectContext, searchResults : [TypeAliases.ResultTuple]) -> NSError? {
        for result in searchResults {
            let (title,reference,weight,index,moddate,summary,content) = result
            let obj = IdolSearchResult(entity: NSEntityDescription.entityForName("IdolSearchResult", inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
            obj.setValue(title, forKeyPath: "title")
            obj.setValue(reference, forKeyPath: "reference")
            obj.setValue(weight, forKeyPath: "weight")
            obj.setValue(index, forKeyPath: "index")
            obj.setValue(moddate, forKeyPath: "moddate")
            obj.setValue(summary, forKeyPath: "summary")
            obj.setValue(content, forKeyPath: "content")
        }
        
        return nil
    }
    
    // Determine if there is any data stored. Useful to determine whether to run a 
    // auto refresh when SelectIndexPanel is shown
    public class func hasIndexList(managedObjectContext: NSManagedObjectContext) -> Bool {
        var freq = NSFetchRequest(entityName: "IdolIndex")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        return res!.count > 0
    }
    
    //Get a list of all the stored indexes
    public class func fetchIndexes(managedObjectContext : NSManagedObjectContext, privateOnly : Bool) -> [TypeAliases.IndexTuple] {
        var freq = NSFetchRequest(entityName: "IdolIndex")
        freq.predicate = privateOnly ? NSPredicate(format: "isPublic=%@", argumentArray: [!privateOnly]) : nil
        
        var err : NSError? = NSError()
        let res = managedObjectContext.executeFetchRequest(freq, error: nil) as? [IdolIndex]
        
        var ret : [TypeAliases.IndexTuple] = []
        
        for r in res! {
            let e : TypeAliases.IndexTuple = (r.name,r.flavor,r.isPublic.boolValue,r.info,r.type)
            ret.append(e)
        }

        return ret
    }
    
    // Core Data methods
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.twopi.IDOLBox" in the application's documents Application Support directory.
        let url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(Constants.GroupContainerName)
        return url as NSURL!
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let bundle = NSBundle(identifier: "com.twopi.IDOLBoxFramework")
        let modelURL = bundle?.URLForResource("IDOLBox", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("IDOLBox.sqlite")
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
            error = NSError(domain: "IDOLBox", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    // Use this to obtain the managed object context
    public lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
}
