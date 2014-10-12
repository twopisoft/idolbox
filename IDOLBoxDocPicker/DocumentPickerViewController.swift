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

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, UITableViewDelegate {
    
    private var _managedObjectContext : NSManagedObjectContext!
    
    private var _apiKey : String!
    private var _indexes : [TypeAliases.IndexTuple]!
    
    private var _fileCoordinator: NSFileCoordinator {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = self.providerIdentifier
        return fileCoordinator
    }
    
    override func viewDidLoad() {
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        readSettings()
        //createDestDirectory()
    }

    override func prepareForPresentationInMode(mode: UIDocumentPickerMode) {
        if self._apiKey == nil || self._apiKey.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: {
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            })
        } else {
            if mode == UIDocumentPickerMode.Import {
                let indexes = DBHelper.fetchIndexes(DBHelper.sharedInstance.managedObjectContext!, privateOnly: true)
                self._indexes = indexes
                performSegueWithIdentifier(Constants.SelectDocSegue, sender: nil)
            }
        }
    }
    
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
            
            NSLog("selected ref=\(vc.selectedReference)")
            if let ref = vc.selectedReference {
                let url = NSURL(string: ref)!
                let fileName = url.lastPathComponent
                
                //let tempDir = NSTemporaryDirectory().stringByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
                //let dirUrl = NSURL(fileURLWithPath: tempDir, isDirectory: true)
                
                //let placeholderURL = dirUrl.URLByAppendingPathComponent(fileName)
                let placeholderURL = self.documentStorageURL.URLByAppendingPathComponent(fileName)
                
                NSLog("placeholderURL=\(placeholderURL)")
                
                let str = "These are the contents of the file"
                let data = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                var e1: NSError? = nil
                data?.writeToURL(placeholderURL, options: NSDataWritingOptions.AtomicWrite, error: &e1)
                if e1 != nil {
                    NSLog("e1=\(e1?.localizedDescription)")
                }
                
                dismissGrantingAccessToURL(placeholderURL)
            }
        }
    }
    
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: "group.com.twopi.IDOLBox")
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
    }
    
    private func createDestDirectory() {
        /*self._fileCoordinator.coordinateWritingItemAtURL(self.documentStorageURL, options: NSFileCoordinatorWritingOptions(), error: nil, byAccessor: { newURL in
            // ensure the documentStorageURL actually exists
            
            var e : NSError? = nil
            if self.documentStorageURL.checkResourceIsReachableAndReturnError(&e) {
                var error: NSError? = nil
                NSFileManager.defaultManager().createDirectoryAtURL(newURL, withIntermediateDirectories: true, attributes: nil, error: &error)
            } else {
                NSLog("documentStorageURL is not accessible: \(e?.localizedDescription)")
            }
            
        })*/
        self._fileCoordinator.coordinateWritingItemAtURL(self.documentStorageURL, options: NSFileCoordinatorWritingOptions(), error: nil, byAccessor: { newURL in
            // ensure the documentStorageURL actually exists
            var error: NSError? = nil
            NSFileManager.defaultManager().createDirectoryAtURL(newURL, withIntermediateDirectories: true, attributes: nil, error: &error)
            if error != nil {
                NSLog("error creating directory: \(error?.localizedDescription)")
            }
        })
    }
}
