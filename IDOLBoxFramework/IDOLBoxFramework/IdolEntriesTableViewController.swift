//
//  IdolEntriesTableViewController.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 13/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData

// UITableViewController for providing basic functionality to display search results
// Subclasses must override some of the methods to provide specific behavior
public class IdolEntriesTableViewController: UITableViewController {

    public var apiKey              : String!
    public var indexes             : [TypeAliases.IndexTuple]!  // List of user's personal indexes
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
    }
    
    // MARK: - Table view data source
    
    // Section count
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchController().sections {
            return sections.count
        }
        return 0
    }
    
    // Row count in a section
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                return secInfo.numberOfObjects
            }
        }
        return 0
    }
    
    // MARK: -Table view delegate
    
    // Cell for a row. Note subclasses must provide the cellConfigHandler method to configure the cell according
    // to the need
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as UITableViewCell
        
        return cellConfigHandler(fetchController(), cell: cell, indexPath: indexPath)
    }
    
    // Section title: All section names are prefixed with "Index :" as all sections represent indexes contents
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                return "Index: \(secInfo.name!)"
            }
        }
        return nil
    }
    
    // Section index titles, the index is show at the right hand side of the table and provides means to navigate
    // the sections
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return fetchController().sectionIndexTitles
    }
    
    // Return the section index given a title
    override public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchController().sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    // MARK: Functions for subclasses to override
    // Basic doSearch routine. Subclasses can override it for their need
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

    
    // To be overriden by the subclass if needed. Any actions that are needed before search is executed
    public func doSearchPre() {
        
    }
    
    // To be overriden by the subclass if needed. Any post search actions can be done here
    public func finishSearch() {
        
    }
    
    // The actual table view outlet. Subclasses must override to return their respective outlets
    public func tableView() -> UITableView! {
        return nil
    }
    
    // Cell config handler to be provided by the subclass. It is used in tableView:cellForRowAtIndexPath
    public func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell! {
        NSException(name: "NotImplemeted", reason: "This method must be implemented by the subclass", userInfo: nil).raise()
        return nil
    }
    
    // How to handle search results. Subclass must provide its logic here
    public func handleSearchResults(data : NSData?, err: NSError?) {
        NSException(name: "NotImplemeted", reason: "This method must be implemented by the subclass", userInfo: nil).raise()
    }
    
    // The subclass specific fecth results controller instance
    public func fetchController() -> NSFetchedResultsController! {
        NSException(name: "NotImplemeted", reason: "This method must be implemented by the subclass", userInfo: nil).raise()
        return nil
    }

}
