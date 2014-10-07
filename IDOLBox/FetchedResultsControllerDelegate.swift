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
   
    private var _tableView : UITableView!
    
    init(tableView : UITableView) {
        self._tableView = tableView
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
            let cell = tabView.cellForRowAtIndexPath(indexPath!)
            let obj = controller.objectAtIndexPath(indexPath!) as IdolIndexes
            cell?.textLabel?.text = obj.name
            
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
}
