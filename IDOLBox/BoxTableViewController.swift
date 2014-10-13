//
//  BoxTableViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 13/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

class BoxTableViewController: IdolEntriesTableViewController {

    @IBOutlet var boxTableView: UITableView!
    
    var selectedItem : IdolBoxEntry!
    
    private var _fetchController : NSFetchedResultsController!
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate!
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    private var _summaryStyle : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        
        readSettings()
        
        doSearch()
    }

    @IBAction func refresh(sender: AnyObject) {
        doSearch()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self._fetchController = nil
    }
    
    override func tableView() -> UITableView! {
        return boxTableView
    }

    override func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolBoxEntry
        
        cell.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell.detailTextLabel!.text = obj.reference
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let si = fetchController().objectAtIndexPath(indexPath) as? IdolBoxEntry
        
        if si != nil {
            selectedItem = si
            performSegueWithIdentifier("BoxEntryDetail", sender: self)
        }
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
    
    override func doSearch() {
        
        if apiKey == nil || apiKey!.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: nil)
            return
        }
        
        doSearchPre()
        
        let searchParams = [Constants.MaxResultParam:Constants.MaxResultsPerIndex,
                            Constants.SummaryParam:_summaryStyle.lowercaseString,
                            Constants.PrintFieldParam:Constants.PrintFieldDate]
        
        for (i,index) in enumerate(self.indexes) {
            
            IDOLService.sharedInstance.queryTextIndex(apiKey, text: "*", index: index.name, searchParams: searchParams, completionHandler: { (data:NSData?, error:NSError?) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.handleSearchResults(data, err: error)
                })
                
                if i == self.indexes.count - 1 {
                    self.finishSearch()
                }
            })
        }
    }
    
    override func handleSearchResults(data : NSData?, err: NSError?) {
        
        if err == nil {
            let results = SearchResultParser.parseResponse(data)
            DBHelper.storeBoxEntries(self._managedObjectContext, searchResults: results)
        } else {
            ErrorReporter.showErrorAlert(self, error: err!)
        }
    }
    
    override func finishSearch() {
        refreshControl?.endRefreshing()
    }
    
    override func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "index", ascending: true),NSSortDescriptor(key: "title", ascending: true)]
            
            var fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("IdolBoxEntry", inManagedObjectContext: self._managedObjectContext)
            fetchRequest.entity = entity
            fetchRequest.sortDescriptors = sortDescriptors
            
            _fetchControllerDelegate = FetchedResultsControllerDelegate(tableView: self.tableView(), configHandler : self.cellConfigHandler)
            
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self._managedObjectContext, sectionNameKeyPath: "index", cacheName: nil)
            _fetchController!.delegate = _fetchControllerDelegate
        }
        
        return _fetchController!
    }
    
    @IBAction func unwindFromSettings(segue : UIStoryboardSegue) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let identifier = segue.identifier
        
        if identifier == "BoxEntryDetail" {
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SearchResultDetailViewController
            
            let entity = NSEntityDescription.entityForName("IdolSearchResult", inManagedObjectContext: self._managedObjectContext)
            var idolSearchResult = IdolSearchResult(entity: entity!, insertIntoManagedObjectContext: self._managedObjectContext)
            idolSearchResult.setValue(selectedItem.title, forKey: "title")
            idolSearchResult.setValue(selectedItem.reference, forKey: "reference")
            idolSearchResult.setValue(selectedItem.index, forKey: "index")
            idolSearchResult.setValue(selectedItem.moddate, forKey: "moddate")
            idolSearchResult.setValue(selectedItem.summary, forKey: "summary")
            idolSearchResult.setValue(selectedItem.content, forKey: "content")
            idolSearchResult.setValue(100, forKey: "weight")
            viewController.selectedItem = idolSearchResult
        }
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        indexes = DBHelper.fetchIndexes(self._managedObjectContext, privateOnly: true)
        _summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
    }

}
