//
//  FindViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

// View controller for Find (Search) View
class FindViewController: UITableViewController, UITextFieldDelegate {

    // MARK: Properties
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    private var _apiKey : String? = nil
    private var _searchIndexes : String? = nil
    private var _searchTerm : String? = nil
    private var _passCodeEnbaled : Bool?
    private var _passCodeVal : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readSettings()
        registerForSettingsChange()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Enable button to respond to events
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 {
            self.searchButton.becomeFirstResponder()
        }
    }
    
    // When user pressed enter or Go, start the search
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
        
        search(self)
        return true
    }
    
    @IBAction func search(sender: AnyObject) {
        readControls()
        if !_searchTerm!.isEmpty {
            performSegueWithIdentifier(Constants.SearchResultSegue, sender: self)
        }
    }
    
    // Passcode setting/validation before moving to settings screen
    @IBAction func settings(sender: AnyObject) {
        SettingsLoginHandler.validate(self, passcodeFlag: self._passCodeEnbaled, passCodeVal: self._passCodeVal)
    }
    
    // MARK: - Navigation
    
    // Unwind action for returning back from Settings screen
    @IBAction func unwindFromSettings(segue : UIStoryboardSegue) {
        
    }
    
    // Unwind action for returning back from Search Result screen
    @IBAction func unwindFromSearchResult(segue : UIStoryboardSegue) {
        
    }
    
    // Unwind action for returning from the index selection screen
    @IBAction func unwindFromSelection(segue : UIStoryboardSegue) {
        if segue.sourceViewController.isKindOfClass(SelectIndexTableViewController) {
            let vc = segue.sourceViewController as SelectIndexTableViewController
            
            if vc.multiSelect {
                _searchIndexes = vc.selectedIndexes.count > 0 ? ",".join(vc.selectedIndexes) : ""
            }
        }
    }

    // Pass data to View Controllers before navigating to them
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        let identifier = segue.identifier
        if identifier == Constants.FindSelectIndexSegue { // For going to Select Index screen
            
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SelectIndexTableViewController
            viewController.apiKey = _apiKey
            viewController.multiSelect = true
            if let si = _searchIndexes {
                viewController.selectedIndexes =  si.isEmpty ? [] : si.componentsSeparatedByString(",")
            }
        } else if identifier == Constants.SearchResultSegue { // For going to Search Result screen
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SearchResultTableViewController
            viewController.apiKey = _apiKey
            if let si = _searchIndexes {
                viewController.selectedIndexes = si.isEmpty ? [Constants.DefaultSearchIndex] : si.componentsSeparatedByString(",")
            } else {
                viewController.selectedIndexes = [Constants.DefaultSearchIndex]
            }
            viewController.searchTerm = _searchTerm
        }
    }
    
    // MARK: Helper method
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        _apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        _searchIndexes = defaults!.valueForKey(Constants.kSearchIndexes) as? String
        _passCodeEnbaled = defaults!.valueForKey(Constants.kSettingsPasscode) as? Bool
        _passCodeVal = defaults!.valueForKey(Constants.kSettingsPasscodeVal) as? String
    }
    
    func settingsChanged(notification : NSNotification!) {
        readSettings()
    }
    
    private func registerForSettingsChange() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    private func readControls() {
        _searchTerm = Utils.trim(searchTextField.text)
    }
}
