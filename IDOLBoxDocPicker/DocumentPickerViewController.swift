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
    
    @IBAction func gotoIdol(sender: AnyObject) {
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: "group.com.twopi.IDOLBox")
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
    }
}
