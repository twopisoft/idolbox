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
    
    private var _fileCoordinator : NSFileCoordinator {
        let fc = NSFileCoordinator()
        fc.purposeIdentifier = self.providerIdentifier
        return fc
    }
    
    override func viewDidLoad() {
        self._managedObjectContext = DBHelper.sharedInstance.managedObjectContext
        readSettings()
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
                let refUrl = NSURL(string: ref)!
                
                let fileUrl = self.placeholderURL(refUrl)
                
                if NSFileManager.defaultManager().fileExistsAtPath(fileUrl.path!) {
                    NSFileManager.defaultManager().removeItemAtURL(fileUrl, error: nil)
                }
                
                NSLog("placeholderURL=\(fileUrl)")
                
                /*self._fileCoordinator.coordinateWritingItemAtURL(fileUrl, options: NSFileCoordinatorWritingOptions(), error: nil, byAccessor: { newUrl in
                    
                    let str = "These are the contents of the file"
                    let data = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                    var e1: NSError? = nil
                    data?.writeToURL(newUrl, options: NSDataWritingOptions.AtomicWrite, error: &e1)
                    
                    if e1 != nil {
                        NSLog("e1=\(e1?.localizedDescription)")
                        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
                    } else {
                        self.dismissGrantingAccessToURL(newUrl)
                    }
                })*/
                
                download(refUrl, fileUrl: fileUrl)
            }
        }
    }
    
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: "group.com.twopi.IDOLBox")
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
    }
    
    private func placeholderURL(url : NSURL) -> NSURL {
        let fileName = url.lastPathComponent
        
        let tempDir = NSTemporaryDirectory()
        let dirUrl = NSURL(fileURLWithPath: tempDir, isDirectory: true)
        
        return dirUrl.URLByAppendingPathComponent(fileName)
    }
    
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
