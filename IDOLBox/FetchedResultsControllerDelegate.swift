//
//  FetchedResultsControllerDelegate.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData

class FetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
   
    typealias ConfigHandler = (controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell
    
    private var _tableView : UITableView!
    private var _cellConfigHandler : ConfigHandler?
    
    init(tableView : UITableView, configHandler : ConfigHandler?) {
        self._tableView = tableView
        self._cellConfigHandler = configHandler
    }
    
    // MARK: NSFetchedResultsControllerDelegate methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self._tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self._tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        var tabView = self._tableView
        
        switch (type) {
        case NSFetchedResultsChangeType.Insert:
            tabView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Delete:
            tabView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Update:
            if self._cellConfigHandler != nil {
                let cell = self._tableView.cellForRowAtIndexPath(indexPath!)
                self._cellConfigHandler!(controller: controller, cell: cell! ,indexPath: indexPath!)
            }
            
        case NSFetchedResultsChangeType.Move:
            tabView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            tabView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        var tabView = self._tableView
        
        switch(type) {
        case NSFetchedResultsChangeType.Insert:
            tabView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Delete:
            tabView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
            
        default: break
        }
    }
    
    func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String!) -> String! {
        return sectionName
    }
}
