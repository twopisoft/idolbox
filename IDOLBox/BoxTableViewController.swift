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

class BoxTableViewController: IdolEntriesTableViewController,UIDocumentPickerDelegate {

    @IBOutlet var boxTableView: UITableView!
    
    var selectedItem : IdolBoxEntry!
    
    private var _fetchController : NSFetchedResultsController!
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate!
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    private var _summaryStyle : String!
    private var _addIndex : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        
        readSettings()
        registerForSettingsChange()
        
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
    
    @IBAction func unwindFromSettings(segue : UIStoryboardSegue) {
        
    }
    
    @IBAction func pickDocument(sender: AnyObject) {
        var docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeText as String,kUTTypePlainText as String,kUTTypePDF as String,kUTTypeRTF as String], inMode: UIDocumentPickerMode.Import)
        docPicker!.delegate = self
        self.presentViewController(docPicker!, animated: true, completion: nil)
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
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        indexes = DBHelper.fetchIndexes(self._managedObjectContext, privateOnly: true)
        _summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
        _addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
    }
    
    func settingsChanged(notification : NSNotification!) {
        readSettings()
    }
    
    private func registerForSettingsChange() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }

}
