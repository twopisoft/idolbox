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

class SelectDocTableViewController: UITableViewController {

    var apiKey              : String!
    var indexes             : [TypeAliases.IndexTuple]!
    var selectedReference   : String!
    
    @IBOutlet var docListTableView: UITableView!
    
    private var _managedObjectContext : NSManagedObjectContext!
    private var _fetchController : NSFetchedResultsController? = nil
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate? = nil

    private var _refreshBarButton : UIBarButtonItem!
    
    private lazy var activityIndicator : UIActivityIndicatorView = {
        var actInd = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        actInd.hidesWhenStopped = true
        return actInd
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        
        self._refreshBarButton = self.navigationItem.rightBarButtonItem
        
        doSearch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        self._fetchController = nil
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchController().sections {
            return sections.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                return secInfo.numberOfObjects
            }
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as UITableViewCell
        
        return cellConfigHandler(fetchController(), cell: cell, indexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                return "Index: \(secInfo.name)"
            }
        }
        return nil
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return fetchController().sectionIndexTitles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchController().sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedItem = fetchController().objectAtIndexPath(indexPath) as? IdolSearchResult
        
        if selectedItem != nil {
            selectedReference = selectedItem?.reference
            performSegueWithIdentifier("unwindFromSelection", sender: self)
        }
    }
    
    func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolSearchResult
        
        cell.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell.detailTextLabel!.text = obj.reference
        
        return cell
    }
    
    @IBAction func doSearch() {
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        
        if self.fetchController().performFetch(nil) {
            for obj in self.fetchController().fetchedObjects! {
                self._managedObjectContext.deleteObject(obj as NSManagedObject)
            }
            docListTableView.reloadData()
        }
        
        self.activityIndicator.startAnimating()
        
        for (i,index) in enumerate(self.indexes) {
            
            IDOLService.sharedInstance.queryTextIndex(self.apiKey, text: "*", index: index.name, completionHandler: { (data:NSData?, error:NSError?) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.handleSearchResults(data, err: error)
                })
                
                if i == self.indexes.count - 1 {
                    self.finishSearch()
                }
            })
        }
    }
    
    private func handleSearchResults(data : NSData?, err: NSError?) {
        if err == nil {
            let results = QueryTextIndexResponseParser.parseResponse(data)
            DBHelper.storeSearchResults(self._managedObjectContext, searchResults: results)
        } else {
            ErrorReporter.showErrorAlert(self, error: err!)
        }
    }
    
    private func finishSearch() {
        if self.activityIndicator.isAnimating() {
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
                self.navigationItem.rightBarButtonItem = self._refreshBarButton
            })
        }
    }
    
    private func fetchController() -> NSFetchedResultsController {
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
