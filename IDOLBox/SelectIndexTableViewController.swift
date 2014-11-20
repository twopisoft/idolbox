//
//  SelectIndexTableViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

// View controller for Select Index view
class SelectIndexTableViewController: UITableViewController {

    // MARK: Properties
    var apiKey : String? = nil
    var multiSelect : Bool = false
    var managedObjectContext : NSManagedObjectContext!
    var selectedIndexes : [String] = []
    
    // Lazily create the activity Indicator
    private lazy var activityIndicator : UIActivityIndicatorView = {
        var actInd = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        return actInd
    }()
    
    // Fetch Results Controller and its delegate
    private var _fetchController : NSFetchedResultsController? = nil
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate? = nil
    private var _filterPredicate : NSPredicate? = nil
    private var _defaultPredicate : NSPredicate? = NSPredicate(format: "type==%@", argumentArray:["content"])
    
    @IBOutlet var indexTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = self.multiSelect ? "Indexes for Search" : "Index for Add"
        self.indexTableView.allowsMultipleSelection = self.multiSelect
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.managedObjectContext = appDelegate.managedObjectContext
        
        if !DBHelper.hasIndexList(self.managedObjectContext) {
           refresh(self)
        }
        
        self.fetchController().performFetch(nil)
        
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
    
    // MARK: Table view delegate methods
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("selectIndexCell", forIndexPath: indexPath) as UITableViewCell
        
        let obj = fetchController().objectAtIndexPath(indexPath) as IdolIndex
        cell.textLabel.text = obj.name
        if let i = find(self.selectedIndexes, obj.name) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark // If the index was selected by the user, turn on the
                                                                        // checkmark accessory
            
            if !self.multiSelect {
                // For single select table, select the row that has the check mark. This will be
                // used later in willSelectRowAtIndexPath and didSelectRowAtIndexPath to move the
                // checkmark to newly selected row
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchController().sections {
            if sections.count > 0 {
                let secInfo = fetchController().sections![section] as NSFetchedResultsSectionInfo
                // Appropriately name the section given that isPublic was true or false
                return secInfo.name == "0" ? Constants.PersonalIndexTitle : Constants.PublicIndexTitle
            }
        }
        return nil
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        var ret : [String] = []
        for title in fetchController().sectionIndexTitles {
            // Correctly set the section title based on isPublic field value
            if title as String == "0" {
                ret.append(Constants.PersonalIndexTitle)
            } else {
                ret.append(Constants.PublicIndexTitle)
            }
        }
        
        if ret.count == 0 {
            return fetchController().sectionIndexTitles
        }
        return ret
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return fetchController().sectionForSectionIndexTitle("\(index)", atIndex: index)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if let currentSelPath = tableView.indexPathForSelectedRow() {
            if !self.multiSelect {
                // Remove the check mark from the currently selected index row. Also remove
                // the index name from the selectedIndexes list
                let cell = tableView.cellForRowAtIndexPath(currentSelPath)
                if cell?.accessoryType == UITableViewCellAccessoryType.Checkmark {
                    cell?.accessoryType = UITableViewCellAccessoryType.None
                    if selectedIndexes.count > 0 {
                        selectedIndexes.removeAtIndex(0)
                    }
                }
            }
            
        }
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.multiSelect {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        let indexName = cell?.textLabel.text
        
        // Update the checkmark on the newly selected row
        // For multi select table, selecting row with a check mark will toggle the checkmark
        // For single select table, selecting a row with check mark does not remove the checkmark
        if cell?.accessoryType == UITableViewCellAccessoryType.Checkmark {
            cell?.accessoryType = UITableViewCellAccessoryType.None
            let i = find(self.selectedIndexes, indexName!)
            if i != nil {
                self.selectedIndexes.removeAtIndex(i!)
            }
        } else {
            if self.selectedIndexes.count == 0 {
                self.selectedIndexes = [indexName!]
            } else {
                self.selectedIndexes.append(indexName!)
            }
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
    }
    
    func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolIndex
        
        cell.textLabel.text = obj.name
        
        return cell
    }
    
    @IBAction func refresh(sender: AnyObject) {
        if apiKey == nil || apiKey!.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: nil)
            return
        }
        
        // Remove all objects and reload the table
        self.fetchController().fetchRequest.predicate = _defaultPredicate
        if self.fetchController().performFetch(nil) {
            for obj in self.fetchController().fetchedObjects! {
                self.managedObjectContext.deleteObject(obj as NSManagedObject)
            }
            indexTableView.reloadData()
        }
        self.fetchController().fetchRequest.predicate = _filterPredicate
        
        let oldRightItem = self.navigationItem.rightBarButtonItem
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        self.activityIndicator.startAnimating()
        
        // Fetch data from IDOL List Index service
        IDOLService.sharedInstance.fetchIndexList(apiKey!, completionHandler: {(data:NSData?, error:NSError?) in
            if error == nil {
                let indexes = ListIndexResponseParser.parseResponse(data)
                DBHelper.updateIndexes(self.managedObjectContext, data: indexes)
            } else {
                ErrorReporter.showErrorAlert(self, error: error!, handler: nil)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
                self.navigationItem.rightBarButtonItem = oldRightItem
            })
        })
        
    }
    
    // Before going back to settings view controller, save all the changes in db
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController.isKindOfClass(SettingsViewController) {
            if self.managedObjectContext.hasChanges {
                self.managedObjectContext.save(nil)
            }
        }
    }
    
    // Fetch Results controller creator. Note the sort descriptors specify isPublic for sections and then name for sorting inside 
    // a section
    private func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "isPublic", ascending: true),NSSortDescriptor(key: "name", ascending: true)]
            _filterPredicate = !self.multiSelect ? NSPredicate(format: "(isPublic==%@) AND (type==%@)", argumentArray: [self.multiSelect,"content"]) : _defaultPredicate
            var fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("IdolIndex", inManagedObjectContext: self.managedObjectContext)
            fetchRequest.entity = entity
            fetchRequest.sortDescriptors = sortDescriptors
            fetchRequest.predicate = _filterPredicate
            
            _fetchControllerDelegate = FetchedResultsControllerDelegate(tableView: self.indexTableView, configHandler: self.cellConfigHandler)
            
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "isPublic", cacheName: nil)
            _fetchController!.delegate = _fetchControllerDelegate
        }
        
        return _fetchController!
    }

}
