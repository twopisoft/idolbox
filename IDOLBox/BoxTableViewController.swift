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
import MobileCoreServices

// View Controller for the Box View
class BoxTableViewController: IdolEntriesTableViewController,UIDocumentPickerDelegate {

    // MARK: Properties and Outlets
    @IBOutlet var boxTableView: UITableView!
    
    var selectedItem : IdolBoxEntry!
    
    private var _fetchController : NSFetchedResultsController!
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate!
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    private var _summaryStyle : String!
    private var _addIndex : String!
    private var _passCodeEnbaled : Bool!
    private var _passCodeVal : String!
    
    // Read the settings, register for settings change and kick start the search when this
    // view is loaded.
    override func viewDidLoad() {
        super.viewDidLoad()

        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        
        readSettings()
        registerForSettingsChange()
        
        doSearch()
    }

    // Execute when refresh control wakes up
    @IBAction func refresh(sender: AnyObject) {
        doSearch()
    }
    
    // Setting button action.
    @IBAction func settings(sender: AnyObject) {
        SettingsLoginHandler.validate(self, passcodeFlag: self._passCodeEnbaled, passCodeVal: self._passCodeVal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self._fetchController = nil
    }
    
    // MARK: IdolEntriesTableViewController overriddenmethods
    override func tableView() -> UITableView! {
        return boxTableView
    }

    // Cell Config handler
    override func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolBoxEntry
        
        cell.textLabel!.text = !obj.title.isEmpty ? obj.title : obj.reference
        cell.detailTextLabel!.text = obj.reference
        
        return cell
    }
    
    // MARK: Table View Delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let si = fetchController().objectAtIndexPath(indexPath) as? IdolBoxEntry
        
        if si != nil {
            selectedItem = si
            performSegueWithIdentifier("BoxEntryDetail", sender: self)
        }
    }
    
    // Start the refresh control and reload the table
    override func doSearchPre() {
        
        refreshControl?.beginRefreshing()
        if self.fetchController().performFetch(nil) {
            for obj in self.fetchController().fetchedObjects! {
                self._managedObjectContext.deleteObject(obj as NSManagedObject)
            }
            tableView().reloadData()
        }
    }
    
    // Perform search using the query text index api. We use '*' as text search term to retrieve
    // all the documents stored in IDOL index
    @IBAction override func doSearch() {
        
        if apiKey == nil || apiKey!.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: nil)
            refreshControl?.endRefreshing()
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
    
    // Parse the results and store in DB
    override func handleSearchResults(data : NSData?, err: NSError?) {
        
        if err == nil {
            let results = SearchResultParser.parseResponse(data)

            if results.count > 0 {
                navigationItem.title = Constants.BoxTitle
                DBHelper.storeBoxEntries(self._managedObjectContext, searchResults: results)
            } else {
               navigationItem.title = Constants.BoxEmptyTitle
            }
        } else {
            ErrorReporter.showErrorAlert(self, error: err!)
        }
    }
    
    // Stop refresh control
    override func finishSearch() {
        refreshControl?.endRefreshing()
    }
    
    // Create Fetched result controller. Sort descriptor uses modification date to list documents in a section
    // latest-to-oldest
    override func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "index", ascending: true),NSSortDescriptor(key: "moddate", ascending: false)]
            
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
    
    // MARK: Navigation
    @IBAction func unwindFromSettings(segue : UIStoryboardSegue) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let identifier = segue.identifier
        
        if identifier == "BoxEntryDetail" {
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SearchResultDetailViewController
            
            let resultTuple = TypeAliases.ResultTuple(selectedItem!.title,selectedItem!.reference,100.0,
                selectedItem!.index,selectedItem!.moddate,selectedItem!.summary,selectedItem!.content)
            viewController.selectedItem = resultTuple
        }
    }
    
    // Action when add document '+' button is pressed
    @IBAction func pickDocument(sender: AnyObject) {
        
        if _addIndex == nil || _addIndex!.isEmpty {
            ErrorReporter.addIndexNotSet(self, handler: nil)
            return
        }
        
        var docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String,kUTTypePlainText as String,kUTTypePDF as String,kUTTypeRTF as String], inMode: UIDocumentPickerMode.Import)
        docPicker!.delegate = self
        self.presentViewController(docPicker!, animated: true, completion: nil)
    }
    
    // MARK: Document Picker delegate methods
    func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        NSLog("url=\(url)")
        
        let startAccessingWorked = url.startAccessingSecurityScopedResource()
        let fileCoordinator = NSFileCoordinator()
        var error : NSError? = nil
        
        fileCoordinator.coordinateReadingItemAtURL(url, options: NSFileCoordinatorReadingOptions.allZeros, error: &error, byAccessor: {(newUrl) in
            NSLog("newUrl=\(newUrl)")
            IDOLService.sharedInstance.addToIndexFile(self.apiKey, filePath: newUrl!.absoluteString!, indexName: self._addIndex, completionHandler: { (data, err) -> () in
                if err != nil {
                    NSLog("error: \(err)")
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.doSearch()
                    })
                }
                url.stopAccessingSecurityScopedResource()
            })
        })
    }
    
    func documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
        
    }
    
    // MARK: Helpers
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        indexes = DBHelper.fetchIndexes(self._managedObjectContext, privateOnly: true)
        _summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
        _addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        _passCodeEnbaled = defaults!.valueForKey(Constants.kSettingsPasscode) as? Bool
        _passCodeVal = defaults!.valueForKey(Constants.kSettingsPasscodeVal) as? String
    }
    
    func settingsChanged(notification : NSNotification!) {
        readSettings()
    }
    
    private func registerForSettingsChange() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }

}
