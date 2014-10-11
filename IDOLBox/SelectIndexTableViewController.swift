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

class SelectIndexTableViewController: UITableViewController {

    var apiKey : String? = nil
    var multiSelect : Bool = false
    var managedObjectContext : NSManagedObjectContext!
    var selectedIndexes : [String] = []
    
    private lazy var activityIndicator : UIActivityIndicatorView = {
        var actInd = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        return actInd
    }()
    
    private var _fetchController : NSFetchedResultsController? = nil
    private var _fetchControllerDelegate : FetchedResultsControllerDelegate? = nil
    
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
        return 1
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
        let cell = tableView.dequeueReusableCellWithIdentifier("selectIndexCell", forIndexPath: indexPath) as UITableViewCell
        
        let obj = fetchController().objectAtIndexPath(indexPath) as IdolIndex
        cell.textLabel!.text = obj.name
        if let i = find(self.selectedIndexes, obj.name) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            
            if !self.multiSelect {
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.multiSelect {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        let indexName = cell?.textLabel?.text
        
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
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {

        if let currentSelPath = tableView.indexPathForSelectedRow() {
            if !self.multiSelect {
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
    
    func cellConfigHandler(controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell {
        let obj = controller.objectAtIndexPath(indexPath) as IdolIndex
        
        cell.textLabel!.text = obj.name
        
        return cell
    }
    
    @IBAction func refresh(sender: AnyObject) {
        if apiKey == nil || apiKey!.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: nil)
            return
        }
        
        let oldRightItem = self.navigationItem.rightBarButtonItem
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
        self.activityIndicator.startAnimating()
        
        // Fetch data from IDOL List Index service
        IDOLService.sharedInstance.fetchIndexList(apiKey!, completionHandler: {(data:NSData?, error:NSError?) in
            if error == nil {
                let indexes = ListIndexResponseParser.parseResponse(data)
                DBHelper.updateIndexes(self.managedObjectContext, data: indexes)
            } else {
                ErrorReporter.showErrorAlert(self, error: error!)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
                self.navigationItem.rightBarButtonItem = oldRightItem
            })
        })
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController.isKindOfClass(SettingsViewController) {
            if self.managedObjectContext.hasChanges {
                self.managedObjectContext.save(nil)
            }
        }
    }
    
    private func fetchController() -> NSFetchedResultsController {
        if _fetchController == nil {
            let sortDescriptors : [AnyObject] = [NSSortDescriptor(key: "name", ascending: true)]
            let filterPredicate = !self.multiSelect ? NSPredicate(format: "isPublic=%@", argumentArray: [self.multiSelect]) : nil
            var fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("IdolIndex", inManagedObjectContext: self.managedObjectContext)
            fetchRequest.entity = entity
            fetchRequest.sortDescriptors = sortDescriptors
            fetchRequest.predicate = filterPredicate
            
            _fetchControllerDelegate = FetchedResultsControllerDelegate(tableView: self.indexTableView, configHandler: self.cellConfigHandler)
            
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            _fetchController!.delegate = _fetchControllerDelegate
        }
        
        return _fetchController!
    }

}
