//
//  SelectDocTableViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 12/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

class SelectDocTableViewController: IdolEntriesTableViewController {
    
    var selectedReference : String!
    
    @IBOutlet var docListTableView: UITableView!
    
    private var _fetchController : NSFetchedResultsController!
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate!
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        
        doSearch()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self._fetchController = nil
    }
    
    override func tableView() -> UITableView! {
        return docListTableView
    }
    
    override func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolSearchResult
        
        cell.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell.detailTextLabel!.text = obj.reference
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let si = fetchController().objectAtIndexPath(indexPath) as? IdolSearchResult
        
        if si != nil {
            selectedReference = si?.reference
            performSegueWithIdentifier("unwindFromSelection", sender: self)
        }
    }
    
    @IBAction func refresh() {
        doSearch()
    }
    
    override func doSearchPre() {
        refreshControl?.beginRefreshing()
        
        if self.fetchController().performFetch(nil) {
            for obj in self.fetchController().fetchedObjects! {
                self._managedObjectContext.deleteObject(obj as NSManagedObject)
            }
            tableView().reloadData()
        }
    }
    
    override func handleSearchResults(data : NSData?, err: NSError?) {
        if err == nil {
            let results = QueryTextIndexResponseParser.parseResponse(data)
            if results.count > 0 {
                navigationItem.title = Constants.BoxTitle
                DBHelper.storeSearchResults(self._managedObjectContext, searchResults: results)
            } else {
                navigationItem.title = Constants.BoxEmptyTitle
            }
        } else {
            ErrorReporter.showErrorAlert(self, error: err!)
        }
    }
    
    override func finishSearch() {
        refreshControl?.endRefreshing()
    }
    
    override func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "index", ascending: true),NSSortDescriptor(key: "weight", ascending: true)]
            
            var fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("IdolSearchResult", inManagedObjectContext: self._managedObjectContext)
            fetchRequest.entity = entity
            fetchRequest.sortDescriptors = sortDescriptors
            
            _fetchControllerDelegate = FetchedResultsControllerDelegate(tableView: self.docListTableView, configHandler : self.cellConfigHandler)
            
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self._managedObjectContext, sectionNameKeyPath: "index", cacheName: nil)
            _fetchController!.delegate = _fetchControllerDelegate
        }
        
        return _fetchController!
    }
    
    

}
