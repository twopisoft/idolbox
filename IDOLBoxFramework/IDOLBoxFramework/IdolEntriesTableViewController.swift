//
//  IdolEntriesTableViewController.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 13/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData

public class IdolEntriesTableViewController: UITableViewController {

    public var apiKey              : String!
    public var indexes             : [TypeAliases.IndexTuple]!
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
    }
    
    // MARK: - Table view data source
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchController().sections {
            return sections.count
        }
        return 0
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                return secInfo.numberOfObjects
            }
        }
        return 0
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as UITableViewCell
        
        return cellConfigHandler(fetchController(), cell: cell, indexPath: indexPath)
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                return "Index: \(secInfo.name)"
            }
        }
        return nil
    }
    
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return fetchController().sectionIndexTitles
    }
    
    override public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchController().sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    public func doSearch() {
        
        doSearchPre()
        
        for (i,index) in enumerate(self.indexes) {
            
            IDOLService.sharedInstance.listDocuments(apiKey, index: index.name, completionHandler: { (data:NSData?, error:NSError?) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.handleSearchResults(data, err: error)
                })
                
                if i == self.indexes.count - 1 {
                    self.finishSearch()
                }
            })
        }
    }

    
    public func doSearchPre() {
        
    }
    
    public func finishSearch() {
        
    }
    
    public func tableView() -> UITableView! {
        return nil
    }
    
    public func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell! {
        NSException(name: "NotImplemeted", reason: "This method must be implemented by subclasses", userInfo: nil).raise()
        return nil
    }
    
    public func handleSearchResults(data : NSData?, err: NSError?) {
        NSException(name: "NotImplemeted", reason: "This method must be implemented by subclasses", userInfo: nil).raise()
    }
    
    public func fetchController() -> NSFetchedResultsController! {
        NSException(name: "NotImplemeted", reason: "This method must be implemented by subclasses", userInfo: nil).raise()
        return nil
    }

}
