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

class ActionViewController: UIViewController {

    var jsContent : String!
    var jsUrl : String!
    
    private var _apiKey : String!
    private var _addIndex : String!
    private var _summaryStyle : String!
    
    let pre = "<article style=\"display: block; zoom: 1;\"><div style=\"width:95%; margin:2% 2% 2% 2%;\"><h2 style=\"text-decoration: underline;\">Summary by IDOL</h2><p>"
    let post = "</p></div></article><hr>"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        readSettings()
        
        if let execContext = self.extensionContext {
            let inputItems = execContext.inputItems
            
            for item in inputItems {
                
                let inputItem = item as NSExtensionItem
                
                for provider: AnyObject in inputItem.attachments! {
                    
                    let itemProvider = provider as NSItemProvider
                    
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as NSString) {
                        
                        itemProvider.loadItemForTypeIdentifier(kUTTypePropertyList as NSString, options: nil, completionHandler: { [unowned self] (result: NSSecureCoding!, error: NSError!) -> Void in
                            
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

    @IBAction func summarize(sender: AnyObject) {
        
        /*let summary = "<article style=\"display: block; zoom: 1;\"><div style=\"width:95%; margin:2% 2% 2% 2%;\"><h2 style=\"text-decoration: underline;\">Summary by IDOL</h2><p>The domestic cat \n\n (Felis catus or Felis silvestris catus) is a small, usually furry, domesticated, and carnivorous mammal. Nomenclature and etymology\n\nThe English word cat (Old English catt) is in origin a loanword, introduced to many languages of Europe from Latin cattus  and Byzantine Greek  , including Portuguese and Spanish gato, French chat, German Katze, Lithuanian katė and Old Church Slavonic kotka, among others. While the African wildcat is the ancestral subspecies from which domestic cats are descended, and wildcats and domestic cats can completely interbreed, there are several intermediate stages between domestic pet and pedigree cats on the one hand and those entirely wild animals on the other. This has resulted in mixed usage of the terms, as the domestic cat can be called by its subspecies name, Felis silvestris catus. However, this has been criticized as implausible, because there may have been little reward for such an effort: cats generally do not carry out commands and, although they do eat rodents, other species such as ferrets or terriers may be better at controlling these pests.</p></div></article><hr>"*/
        
        var alert : UIViewController!
        
        dispatch_async(dispatch_get_main_queue(), {
            alert = ActivityProgressAlert.showAlertView(self, title: "Please wait", message: "IDOL is summarizing")
        })
        
        IDOLService.sharedInstance.addToIndexUrl(self._apiKey, url: self.jsUrl, index: self._addIndex, completionHandler: { (data1:NSData?, error1:NSError?) in
            
            if error1 != nil {
                dispatch_async(dispatch_get_main_queue(), {
                    alert.dismissViewControllerAnimated(true, completion: nil)
                })
                
                ErrorReporter.showErrorAlert(self, error: error1!, handler: {
                    self.done()
                })
            } else {
                IDOLService.sharedInstance.findSimilarDocsUrl(self._apiKey, url: self.jsUrl, indexName: self._addIndex, searchParams: [Constants.MaxResultParam : "1", Constants.SummaryParam : self._summaryStyle], completionHandler: { (data2:NSData?, error2:NSError?) in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        alert.dismissViewControllerAnimated(true, completion: nil)
                    })
                    
                    if error2 != nil {
                        ErrorReporter.showErrorAlert(self, error: error1!, handler: {
                            self.done()
                        })
                    } else {
                        let results = SearchResultParser.parseResponse(data2)
                        if results.count > 0 {
                            self.jsContent = self.pre + results[0].summary + self.post + self.jsContent
                            self.finalizeReplace()
                        }
                    }
                })
            }
            
        })
    }
    
    @IBAction func done() {
        finalizeReplace()
    }
    
    private func finalizeReplace() {
        var extensionItem = NSExtensionItem()
        
        var retArgs : [String : String] = ["content" : self.jsContent]
        var item = NSDictionary(object: retArgs, forKey: NSExtensionJavaScriptFinalizeArgumentKey)
        
        var itemProvider = NSItemProvider(item: item, typeIdentifier: kUTTypePropertyList as NSString)
        extensionItem.attachments = [itemProvider]
        
        self.extensionContext!.completeRequestReturningItems([extensionItem], completionHandler: nil)
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        self._apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        self._addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        self._summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
    }

}
