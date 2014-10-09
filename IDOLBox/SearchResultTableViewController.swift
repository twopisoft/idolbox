//
//  SearchResultTableViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData

class SearchResultTableViewController: UITableViewController {
    
    var apiKey : String? = nil
    var searchTerm : String? = nil
    var managedObjectContext : NSManagedObjectContext!
    var selectedIndexes : [String] = []
    
    @IBOutlet var indexTableView: UITableView!
    
    private lazy var activityIndicator : UIActivityIndicatorView = {
        var actInd = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        actInd.hidesWhenStopped = true
        return actInd
    }()
    
    private var _fetchController : NSFetchedResultsController? = nil
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        
        if self.fetchController().performFetch(nil) {
            for obj in self.fetchController().fetchedObjects! {
                self.managedObjectContext.deleteObject(obj as NSManagedObject)
            }
            indexTableView.reloadData()
        }
        
        doSearch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        _fetchController = nil
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
        
        let obj = fetchController().objectAtIndexPath(indexPath) as IdolSearchResults
        cell.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell.detailTextLabel!.text = obj.reference
        return cell
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
    
    func cellConfigHandler(controller: NSFetchedResultsController, tableView : UITableView, indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let obj = controller.objectAtIndexPath(indexPath) as IdolSearchResults
        
        cell!.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell!.detailTextLabel!.text = obj.reference
    }
    
    private func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "index", ascending: true),NSSortDescriptor(key: "weight", ascending: true)]
            
            var fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("IdolSearchResults", inManagedObjectContext: self.managedObjectContext)
            fetchRequest.entity = entity
            fetchRequest.sortDescriptors = sortDescriptors
            
            _fetchControllerDelegate = FetchedResultsControllerDelegate(tableView: self.indexTableView, configHandler : self.cellConfigHandler)
            
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "index", cacheName: nil)
            _fetchController!.delegate = _fetchControllerDelegate
        }
        
        return _fetchController!
    }
    
    private func doSearch() {
        if apiKey == nil || apiKey!.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: nil)
            return
        }
        
        self.activityIndicator.startAnimating()
        
        for (i,index) in enumerate(selectedIndexes) {
            if isUrl(searchTerm!) {
                IDOLService.sharedInstance.findSimilarDocsUrl(apiKey!, url: searchTerm!, indexName: index, completionHandler: { (data : NSData?, err: NSError?) in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.handleSearchResults(data, err: err)
                    })
                    
                    if i == self.selectedIndexes.count - 1 {
                        self.finishSearch()
                    }
                })
            } else {
                IDOLService.sharedInstance.findSimilarDocs(apiKey!, text: searchTerm!, indexName: index, completionHandler: { (data: NSData?, err: NSError?) in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.handleSearchResults(data, err: err)
                    })
                    
                    if i == self.selectedIndexes.count - 1 {
                        self.finishSearch()
                    }
                })
            }
        }
    }
    
    private func handleSearchResults(data : NSData?, err: NSError?) {
        if err == nil {
            let results = SearchResultParser.parseResponse(data)
            DBHelper.storeSearchResults(self.managedObjectContext, searchResults: results)
        } else {
            ErrorReporter.showErrorAlert(self, error: err!)
        }
    }
    
    private func finishSearch() {
        if self.activityIndicator.isAnimating() {
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
            })
        }
    }
    
    private func isUrl(str : String) -> Bool {
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let urlTest = NSPredicate(format: "SELF MATCHES %@", urlRegEx)
        return urlTest!.evaluateWithObject(str)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
