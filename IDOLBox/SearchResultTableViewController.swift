//
//  SearchResultTableViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

class SearchResultTableViewController: IdolEntriesTableViewController {
    
    var searchTerm : String? = nil
    
    var selectedIndexes : [String] = []
    
    private var _selectedItem : IdolSearchResult? = nil
    private var _managedObjectContext : NSManagedObjectContext!
    
    @IBOutlet var resultsTableView: UITableView!
    
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

        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        
        
        
        doSearch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        _fetchController = nil
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        _selectedItem = fetchController().objectAtIndexPath(indexPath) as? IdolSearchResult
        
        if _selectedItem != nil {
            performSegueWithIdentifier(Constants.SearchResultDetailSegue, sender: self)
        }
    }
    
    override func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolSearchResult
        
        cell.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell.detailTextLabel!.text = obj.reference
        
        return cell
    }
    
    override func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "index", ascending: true),NSSortDescriptor(key: "weight", ascending: true)]
            
            var fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("IdolSearchResult", inManagedObjectContext: self._managedObjectContext)
            fetchRequest.entity = entity
            fetchRequest.sortDescriptors = sortDescriptors
            
            _fetchControllerDelegate = FetchedResultsControllerDelegate(tableView: self.resultsTableView, configHandler : self.cellConfigHandler)
            
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self._managedObjectContext, sectionNameKeyPath: "index", cacheName: nil)
            _fetchController!.delegate = _fetchControllerDelegate
        }
        
        return _fetchController!
    }
    
    override func doSearchPre() {
        
        self.activityIndicator.startAnimating()
        
        if self.fetchController().performFetch(nil) {
            for obj in self.fetchController().fetchedObjects! {
                self._managedObjectContext.deleteObject(obj as NSManagedObject)
            }
            resultsTableView.reloadData()
        }
    }
    
    override func doSearch() {
        if apiKey == nil || apiKey!.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: nil)
            return
        }
        
        doSearchPre()
        
        let searchParams = getSearchParams()
        
        for (i,index) in enumerate(selectedIndexes) {
            if Utils.isUrl(searchTerm!) {
                IDOLService.sharedInstance.findSimilarDocsUrl(apiKey!, url: searchTerm!, indexName: index, searchParams: searchParams, completionHandler: { (data : NSData?, err: NSError?) in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.handleSearchResults(data, err: err)
                    })
                    
                    if i == self.selectedIndexes.count - 1 {
                        self.finishSearch()
                    }
                })
            } else {
                IDOLService.sharedInstance.findSimilarDocs(apiKey!, text: searchTerm!, indexName: index, searchParams: searchParams, completionHandler: { (data: NSData?, err: NSError?) in
                    
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
    
   override func handleSearchResults(data : NSData?, err: NSError?) {
        if err == nil {
            let results = SearchResultParser.parseResponse(data)
            DBHelper.storeSearchResults(self._managedObjectContext, searchResults: results)
        } else {
            ErrorReporter.showErrorAlert(self, error: err!)
        }
    }
    
    override func finishSearch() {
        if self.activityIndicator.isAnimating() {
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
            })
        }
    }
    
    private func getSearchParams() -> [String:String] {
        var ret : [String:String] = [:]
        
        let defaults : NSUserDefaults! = NSUserDefaults(suiteName: Constants.GroupContainerName)
        
        if let maxResults = defaults.valueForKey(Constants.kMaxResults) as? Int {
            ret[Constants.MaxResultParam] = "\(maxResults)"
        }
        
        if let summaryStyle = defaults.valueForKey(Constants.kSummaryStyle) as? String {
            ret[Constants.SummaryParam] = summaryStyle.lowercaseString
        }
        
        if let sortStyle = defaults.valueForKey(Constants.kSortStyle) as? String {
            ret[Constants.SortParam] = sortStyle.lowercaseString
        }
        
        ret[Constants.HighlightParam] = Constants.HighlightStyleSummaryTerms
        ret[Constants.StartTagParam] = Constants.StartTagStyle
        
        ret[Constants.PrintFieldParam] = Constants.PrintFieldDate
        
        return ret
        
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let identifier = segue.identifier
        
        if identifier == Constants.SearchResultDetailSegue {
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SearchResultDetailViewController
            
            let resultTuple = TypeAliases.ResultTuple(_selectedItem!.title,_selectedItem!.reference,_selectedItem!.weight,
                                                    _selectedItem!.index,_selectedItem!.moddate,_selectedItem!.summary,_selectedItem!.content)
            viewController.selectedItem = resultTuple
        }
    }
    

}
