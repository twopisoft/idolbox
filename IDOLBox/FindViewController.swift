//
//  FindViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

class FindViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var searchTextField: UITextField!
    
    private var _apiKey : String? = nil
    private var _searchIndexes : String? = nil
    private var _searchTerm : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readSettings()
        registerForSettingsChange()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 {
            self.searchTextField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
        
        readControls()
        if !_searchTerm!.isEmpty {
            performSegueWithIdentifier(Constants.SearchResultSegue, sender: self)
        }
        return true
    }
    
    @IBAction func unwindFromSettings(segue : UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindFromSearchResult(segue : UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindFromSelection(segue : UIStoryboardSegue) {
        if segue.sourceViewController.isKindOfClass(SelectIndexTableViewController) {
            let vc = segue.sourceViewController as SelectIndexTableViewController
            
            if vc.multiSelect {
                _searchIndexes = vc.selectedIndexes.count > 0 ? ",".join(vc.selectedIndexes) : ""
            }
        }
    }
    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        let identifier = segue.identifier
        if identifier == Constants.FindSelectIndexSegue {
            
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SelectIndexTableViewController
            viewController.apiKey = _apiKey
            viewController.multiSelect = true
            if let si = _searchIndexes {
                viewController.selectedIndexes =  si.isEmpty ? [] : si.componentsSeparatedByString(",")
            }
        } else if identifier == Constants.SearchResultSegue {
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SearchResultTableViewController
            viewController.apiKey = _apiKey
            if let si = _searchIndexes {
                viewController.selectedIndexes = si.isEmpty ? [] : si.componentsSeparatedByString(",")
            } else {
                viewController.selectedIndexes = [Constants.DefaultSearchIndex]
            }
            viewController.searchTerm = _searchTerm
        }
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: "group.com.twopi.IDOLBox")
        _apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        _searchIndexes = defaults!.valueForKey(Constants.kSearchIndexes) as? String
    }
    
    func settingsChanged(notification : NSNotification!) {
        readSettings()
    }
    
    private func registerForSettingsChange() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    private func readControls() {
        _searchTerm = searchTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}
