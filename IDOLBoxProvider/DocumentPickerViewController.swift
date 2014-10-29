//
//  DocumentPickerViewController.swift
//  IDOLBoxDocPicker
//
//  Created by TwoPi on 11/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

// View Controller for Document Provider extension
class DocumentPickerViewController: UIDocumentPickerExtensionViewController, UITableViewDelegate {
    
    // MARK: Properties
    private var _managedObjectContext : NSManagedObjectContext!
    
    private var _apiKey : String!
    private var _indexes : [TypeAliases.IndexTuple]!
    
    private var _fileCoordinator : NSFileCoordinator {
        let fc = NSFileCoordinator()
        fc.purposeIdentifier = self.providerIdentifier
        return fc
    }
    
    // MARK: Delaget methods
    override func viewDidLoad() {
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        readSettings()
    }

    // We only support Imports.
    override func prepareForPresentationInMode(mode: UIDocumentPickerMode) {
        if Utils.isNullOrEmpty(self._apiKey) {
            ErrorReporter.apiKeyNotSet(self, handler: {
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            })
        } else {
            if mode == UIDocumentPickerMode.Import {
                // Fetch all personal indexes from DB
                let indexes = DBHelper.fetchIndexes(DBHelper.sharedInstance.managedObjectContext!, privateOnly: true)
                self._indexes = indexes
                performSegueWithIdentifier(Constants.SelectDocSegue, sender: nil)
            }
        }
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let identifier = segue.identifier
        if identifier == Constants.SelectDocSegue {
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SelectDocTableViewController
            viewController.apiKey = self._apiKey
            viewController.indexes = self._indexes
        }
    }
    
    @IBAction func unwindFromSelection(segue : UIStoryboardSegue) {
        if segue.sourceViewController.isKindOfClass(SelectDocTableViewController) {
            let vc = segue.sourceViewController as SelectDocTableViewController
            
            if let ref = vc.selectedReference {
                
                if Utils.isUrl(ref) {
                    let refUrl = NSURL(string: ref)!
                    
                    let fileUrl = self.placeholderURL(refUrl)
                    
                    if NSFileManager.defaultManager().fileExistsAtPath(fileUrl.path!) {
                        NSFileManager.defaultManager().removeItemAtURL(fileUrl, error: nil)
                    }
                    
                    download(refUrl, fileUrl: fileUrl)
                } else {
                    ErrorReporter.showAlertView(self, title: "IDOLBox Error", message: "Only HTTP(S) references are supported", alertHandler: {
                        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
                    })
                }
            }
        }
    }
    
    // MARK: Helpers
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
    }
    
    private func placeholderURL(url : NSURL) -> NSURL {
        let fileName = url.lastPathComponent
        
        let tempDir = NSTemporaryDirectory()
        let dirUrl = NSURL(fileURLWithPath: tempDir, isDirectory: true)
        
        return dirUrl!.URLByAppendingPathComponent(fileName)
    }
    
    // Download document from IDOL index
    private func download(refUrl : NSURL, fileUrl : NSURL) {
        
        var alert : UIViewController!
        
        dispatch_async(dispatch_get_main_queue(), {
            alert = ActivityProgressAlert.showAlertView(self, title: "Please wait", message: "Downloading from IDOL")
        })
        
        IDOLService.sharedInstance.viewDocument(_apiKey!, url: refUrl.absoluteString!, completionHandler: { (data:NSData?, error:NSError?) in
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            if error == nil {
                let document = ViewDocumentResponseParser.parseResponse(data)
                let data = document.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                var e1: NSError? = nil
                data?.writeToURL(fileUrl, options: NSDataWritingOptions.AtomicWrite, error: &e1)
                if e1 != nil {
                    ErrorReporter.showErrorAlert(self, error: e1!, handler: {
                        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
                    })
                } else {
                    self.dismissGrantingAccessToURL(fileUrl)
                }
            } else {
                ErrorReporter.showErrorAlert(self, error: error!, handler: {
                    self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
                })
            }
        })
    }
    
}
