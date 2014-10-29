//
//  ActionViewController.swift
//  IDOLBoxAction
//
//  Created by TwoPi on 10/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import MobileCoreServices
import IDOLBoxFramework

// Custome Action extension View Controller
class ActionViewController: UIViewController {

    // MARK: Properties
    var jsContent : String!    // For page body contents
    var jsUrl : String!        // For page url
    
    private var _apiKey : String!
    private var _addIndex : String!
    private var _summaryStyle : String!
    
    // Inline style specification
    let pre = "<article style=\"display: block; zoom: 1;\"><div style=\"width:95%; margin:2% 2% 2% 2%;\"><h2 style=\"text-decoration: underline;\">Summary by IDOL</h2><p>"
    let post = "</p></div></article><hr>"

    // MARK: Custom Action
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readSettings()
        registerForSettingsChange()
        
        if let execContext = self.extensionContext {
            let inputItems = execContext.inputItems
            
            for item in inputItems {
                
                let inputItem = item as NSExtensionItem
                
                for provider: AnyObject in inputItem.attachments! {
                    
                    let itemProvider = provider as NSItemProvider
                    
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as NSString) {
                        
                        itemProvider.loadItemForTypeIdentifier(kUTTypePropertyList as NSString, options: nil, completionHandler: { [unowned self] (result: NSSecureCoding!, error: NSError!) -> Void in
                            
                            //  Get data from Javascript
                            if let resultDict = result as? NSDictionary {
                                
                                self.jsContent = resultDict[NSExtensionJavaScriptPreprocessingResultsKey]!["content"] as? String
                                self.jsUrl = resultDict[NSExtensionJavaScriptPreprocessingResultsKey]!["url"] as? String
                            }
                            
                        });
                        
                    }
                }
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Summarize the page
    @IBAction func summarize(sender: AnyObject) {
        
        if !validate() {
            return
        }
        
        var alert : UIViewController!
        
        dispatch_async(dispatch_get_main_queue(), {
            alert = ActivityProgressAlert.showAlertView(self, title: "Please wait", message: "IDOL is summarizing")
        })
        
        // First add the document to IDOL
        IDOLService.sharedInstance.addToIndexUrl(self._apiKey, url: self.jsUrl, index: self._addIndex, completionHandler: { (data1:NSData?, error1:NSError?) in
            
            if error1 != nil {
                dispatch_async(dispatch_get_main_queue(), {
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                
                ErrorReporter.showErrorAlert(self, error: error1!, handler: {
                    self.done()
                })
            } else {
                // Then issue a Find Similar document API call. Only read 1 result
                IDOLService.sharedInstance.findSimilarDocsUrl(self._apiKey, url: self.jsUrl, indexName: self._addIndex, searchParams: [Constants.MaxResultParam : "1", Constants.SummaryParam : self._summaryStyle], completionHandler: { (data2:NSData?, error2:NSError?) in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        alert.dismissViewControllerAnimated(true, completion: nil)
                    })
                    
                    if error2 != nil {
                        ErrorReporter.showErrorAlert(self, error: error1!, handler: {
                            self.done()
                        })
                    } else {
                        // Parse the resilt
                        let results = SearchResultParser.parseResponse(data2)
                        if results.count > 0 {
                            if Utils.trim(results[0].summary).isEmpty {
                                ErrorReporter.showAlertView(self, title: "Sorry...", message: "IDOL could not generate a summary", alertHandler: {
                                    self.done()
                                })
                            } else {
                                // Send the updated page body to Javascript
                                self.jsContent = self.pre + results[0].summary + self.post + self.jsContent
                                self.finalizeReplace()
                            }
                        }
                    }
                })
            }
            
        })
    }
    
    // Cancel action
    @IBAction func done() {
        finalizeReplace()
    }
    
    // Pass the result back to Javascript
    private func finalizeReplace() {
        var extensionItem = NSExtensionItem()
        
        var retArgs : [String : String] = ["content" : self.jsContent]
        var item = NSDictionary(object: retArgs, forKey: NSExtensionJavaScriptFinalizeArgumentKey)
        
        var itemProvider = NSItemProvider(item: item, typeIdentifier: kUTTypePropertyList as NSString)
        extensionItem.attachments = [itemProvider]
        
        self.extensionContext!.completeRequestReturningItems([extensionItem], completionHandler: nil)
    }
    
    // MARK: Helpers
    private func validate() -> Bool {
        if Utils.isNullOrEmpty(self._apiKey) {
            ErrorReporter.apiKeyNotSet(self, handler: {
                self.done()
            })
            return false
        } else if Utils.isNullOrEmpty(self._addIndex) {
            ErrorReporter.addIndexNotSet(self, handler: {
                self.done()
            })
            return false
        }
        
        return true
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        self._addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        self._summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
    }
    
    func settingsChanged(notification : NSNotification!) {
        readSettings()
    }
    
    private func registerForSettingsChange() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }

}
