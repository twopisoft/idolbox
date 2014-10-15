//
//  SearchResultDetailViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 9/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

// View Controller for Search Result Detail View
class SearchResultDetailViewController: UIViewController, UIWebViewDelegate {

    // Properties
    var selectedItem : TypeAliases.ResultTuple?
    
    @IBOutlet weak var detailWebView: UIWebView!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var stopButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.detailWebView.delegate = self
        loadPage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: WebView Delegate methods
    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        updateButtons()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        updateButtons()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        updateButtons()
    }
    
    // Back button action
    // Note that the back button is never disabled. On the last page
    // it will keep showing the first page.
    @IBAction func back(sender: AnyObject) {
        if !self.detailWebView.canGoBack {
            loadPage()
        } else {
            self.detailWebView.goBack()
        }
    }
    
    // MARK: Helpers
    private func loadPage() {
        let baseUrl = NSURL(fileURLWithPath: NSBundle.mainBundle().bundlePath)
        self.detailWebView.loadHTMLString(processTemplate(self.selectedItem!), baseURL: baseUrl)
    }
    
    // Update WebView's button status
    private func updateButtons() {
        self.forwardButton.enabled = self.detailWebView.canGoForward
        self.stopButton.enabled = self.detailWebView.loading
        self.reloadButton.enabled = !self.detailWebView.loading
    }
    
    // Pass the data to template processor. Modification date is not set if not
    // found in the search result
    private func processTemplate(data : TypeAliases.ResultTuple) -> String {
        
        var fields : [String : String] = ["title"       : data.title,
                                          "reference"   : data.reference,
                                          "index"       : data.index,
                                          "summary"     : data.summary,
                                          "content"     : data.content]
        
        
        
        let weight = NSString(format: "%5.2f", data.weight)
        fields["weight"] = weight
        
        var moddate = ""
        if data.moddate != NSDate.distantFuture() as NSDate {
            moddate = "Modified on: " + NSDateFormatter.localizedStringFromDate(data.moddate, dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: NSDateFormatterStyle.LongStyle)
        }
        fields["moddate"] = moddate
        
        return ViewDocumentTemplateProcessor.processTemplate(fields)
    }

}
