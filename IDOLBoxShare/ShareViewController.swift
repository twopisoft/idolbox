//
//  ShareViewController.swift
//  IDOLBoxShare
//
//  Created by TwoPi on 10/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import Social
import IDOLBoxFramework
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {

    private var _url : NSURL!
    private var _apiKey : String!
    private var _addIndex : String!
    
    override func viewDidLoad() {
        //self.textView.editable = true
        
        readSettings()
    }
    
    override func presentationAnimationDidFinish() {
        
        self.textView.editable = false
        let extensionItem = self.extensionContext?.inputItems[0] as NSExtensionItem
        
        for attachment in extensionItem.attachments as [NSItemProvider] {
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL) {
                attachment.loadItemForTypeIdentifier(kUTTypeURL, options: nil, completionHandler: { (urlProvider, error) in
                    if let e = error {
                        NSLog("Error while reading attachment: \(error.localizedDescription)")
                    } else {
                        self._url = urlProvider as? NSURL
                    }
                })
            }
        }
    }
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        if self._apiKey == nil || self._apiKey.isEmpty {
            ErrorReporter.apiKeyNotSet(self, handler: {
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            })
        } else if self._addIndex == nil || self._addIndex.isEmpty {
            ErrorReporter.addIndexNotSet(self, handler: {
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            })
        } else {
            IDOLService.sharedInstance.addToIndexUrl(self._apiKey, url: self._url.absoluteString!, index: self._addIndex, completionHandler: { (data:NSData?, error:NSError?) in
                if let e = error {
                    NSLog("Failed while adding to Index: \(e.localizedDescription)")
                } else {
                    NSLog("Successfully added to Index")
                }
            })
            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
        }
    }

    override func configurationItems() -> [AnyObject]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return NSArray()
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: "group.com.twopi.IDOLBox")
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        self._addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        NSLog("_apiKey=\(_apiKey)")
    }

}
