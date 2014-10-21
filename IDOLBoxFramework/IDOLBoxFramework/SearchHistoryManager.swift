//
//  HistoryManager.swift
//  IDOLBox
//
//  Created by TwoPi on 20/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData

class SearchHistoryManager: NSObject {
   
    private var _managedObjectContext : NSManagedObjectContext!
    
    init(managedObjectContext : NSManagedObjectContext) {
        self._managedObjectContext = managedObjectContext
    }
    
    func updateHistory(searchTerm : String, indexes : String, results : [IdolSearchResult]) {
        
        if var term = findSearchTerm(searchTerm) {
            term.setValue(searchTerm, forKey: "term")
            term.setValue(NSDate(), forKey: "timestamp")
            term.setValue(indexes, forKey: "indexes")
            term.setValue(NSSet(array: results), forKey: "results")
            
            save()
        }
    }
    
    func clearHistory() {
        if let terms = fetchSearchTerms() {
            for term in terms  {
                self._managedObjectContext.deleteObject(term)
            }
            
            save()
        }
    }
    
    func deleteTerm(searchTerm : String) {
        if let term = findSearchTerm(searchTerm) {
            self._managedObjectContext.deleteObject(term)
            
            save()
        }
    }
    
    func searchTerms() -> [String]? {
        
        if let terms = fetchSearchTerms() {
            var ret : [String] = []
            
            for term in terms {
                ret.append(term.valueForKey("term") as String)
            }
            
            return ret
        }
        
        return nil
    }
    
    func searchTermsLike(searchPat : String) -> [String]? {
        if let terms = fetchSearchTerms(searchPat: searchPat) {
            var ret : [String] = []
            
            for term in terms {
                ret.append(term.valueForKey("term") as String)
            }
            
            return ret
        }
        
        return nil
    }
    
    private func fetchSearchTerms(searchPat : String? = nil) -> [IdolSearch]? {
        let freq = NSFetchRequest(entityName: "IdolSearch")
        if var sp = searchPat {
            sp = Utils.trim(sp)
            if !sp.isEmpty {
                freq.predicate = NSPredicate(format: "term LIKE[c] %@", argumentArray: [sp])
            }
        }
        freq.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let res = self._managedObjectContext.executeFetchRequest(freq, error: nil)
        
        if let terms = res as? [IdolSearch] {
            return terms
        }
        
        return nil
    }
    
    private func findSearchTerm(searchTerm : String) -> IdolSearch? {
        var freq = NSFetchRequest(entityName: "IdolSearch")
        let pred = NSPredicate(format: "term == %@", argumentArray: [searchTerm])
        
        freq.predicate = pred
        freq.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let res = self._managedObjectContext.executeFetchRequest(freq, error: nil)
        
        if let terms = res as? [IdolSearch] {
            if terms.count > 0 {
                return terms[0]
            }
        }
        
        return nil
    }
    
    private func save() {
        var err : NSError? = nil
        self._managedObjectContext.save(&err)
        
        if err != nil {
            NSLog("SearchHistoryManager: Error while saving data: %@",err!.localizedDescription)
        }
    }
}
