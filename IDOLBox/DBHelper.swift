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

class DBHelper {
    
    // MARK: Typealiases
    // Tuple for index info
    typealias IndexTuple = (name:String,flavor:String,isPublic:Bool,info:String)
    
    // Tuple for Search Result
    typealias ResultTuple = (title:String,reference:String,weight:Double,index:String,moddate:NSDate,summary:String,content:String)
    
    // MARK: Data handlers for index information
    
    // Update index data. This involves:
    // 1. From the data coming in from List Index service, find what indexes are updated
    // 2. And which of the indexes have been deleted
    // 3. Finally, add the new index entries
    class func updateIndexes(managedObjectContext : NSManagedObjectContext, data : [IndexTuple]) -> NSError? {
        var foundObjs :[Int:IndexTuple] = [:]
        
        var freq = NSFetchRequest(entityName: "IdolIndexes")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        
        for mo in res! {
            var found = false
            for (i,entry) in enumerate(data) {
                let (indexName,indexFlavor,isPublic,indexInfo) = entry
                
                // First update existing indexes info
                if mo.name == indexName {
                    found = true
                    mo.setValue(indexFlavor, forKey: "flavor")
                    mo.setValue(isPublic, forKey: "isPublic")
                    mo.setValue(indexInfo, forKey: "info")
                    foundObjs[i]=entry
                }
            }
            
            // Delete the ones, that no longer exist on the server
            if !found {
                managedObjectContext.deleteObject(mo as NSManagedObject)
            }
        }
        
        // Finally, add the new index entries
        var newData : [IndexTuple] = []
        for (i,entry) in enumerate(data) {
            if foundObjs[i] == nil {
                newData.append(entry)
            }
        }
        
        for newEntry in newData {
            let (indexName,indexFlavor,isPublic,indexInfo) = newEntry
            let obj = IdolIndexes(entity: NSEntityDescription.entityForName("IdolIndexes", inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
            obj.setValue(indexName, forKey: "name")
            obj.setValue(indexFlavor, forKey: "flavor")
            obj.setValue(isPublic, forKey: "isPublic")
            obj.setValue(indexInfo, forKey: "info")
        }
        
        return nil
    }
    
    class func storeSearchResults(managedObjectContext : NSManagedObjectContext, searchResults : [ResultTuple]) -> NSError? {
        for result in searchResults {
            let (title,reference,weight,index,moddate,summary,content) = result
            let obj = IdolSearchResults(entity: NSEntityDescription.entityForName("IdolSearchResults", inManagedObjectContext: managedObjectContext)!, insertIntoManagedObjectContext: managedObjectContext)
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
    class func hasIndexList(managedObjectContext: NSManagedObjectContext) -> Bool {
        var freq = NSFetchRequest(entityName: "IdolIndexes")
        let res = managedObjectContext.executeFetchRequest(freq, error: nil)
        return res!.count > 0
    }
}
