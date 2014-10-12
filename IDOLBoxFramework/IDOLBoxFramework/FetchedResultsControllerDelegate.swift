//
//  FetchedResultsControllerDelegate.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData

public class FetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    private var _tableView : UITableView!
    private var _cellConfigHandler : TypeAliases.ConfigHandler?
    
    public init(tableView : UITableView, configHandler : TypeAliases.ConfigHandler?) {
        self._tableView = tableView
        self._cellConfigHandler = configHandler
    }
    
    // MARK: NSFetchedResultsControllerDelegate methods
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self._tableView.beginUpdates()
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self._tableView.endUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        var tabView = self._tableView
        
        switch (type) {
        case NSFetchedResultsChangeType.Insert:
            tabView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Delete:
            tabView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Update:
            if self._cellConfigHandler != nil {
                let cell = self._tableView.cellForRowAtIndexPath(indexPath!)
                NSLog("indexPath.section=\(indexPath?.section), indexPath.row=\(indexPath?.row)")
                NSLog("cell=\(cell)")
                self._cellConfigHandler!(controller: controller, cell: cell! ,indexPath: indexPath!)
            }
            
        case NSFetchedResultsChangeType.Move:
            tabView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            tabView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        var tabView = self._tableView
        
        switch(type) {
        case NSFetchedResultsChangeType.Insert:
            tabView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Delete:
            tabView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            
        default: break
        }
    }
    
    public func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String!) -> String! {
        return sectionName
    }
}
