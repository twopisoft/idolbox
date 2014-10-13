//
//  SettingsViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

class SettingsViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var maxResultButton: UISegmentedControl!
    @IBOutlet weak var summaryStyleButton: UISegmentedControl!
    @IBOutlet weak var sortStyleButton: UISegmentedControl!
    @IBOutlet weak var passcodeSwitch: UISwitch!
    
    private var _apiKey : String? = nil
    private var _maxResults : Int? = 5
    private var _summaryStyle : String? = Constants.SummaryStyleQuick
    private var _sortStyle : String? = Constants.SortStyleRelevance
    private var _settingsPasscode : Bool? = true
    private var _searchIndexes : String? = nil
    private var _addIndex : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettings()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            self.apiKeyTextField.becomeFirstResponder()
        }
    }

    @IBAction func save(sender: AnyObject) {
        readControls()
        var defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        defaults!.setObject(_apiKey, forKey: Constants.kApiKey)
        defaults!.setInteger(_maxResults!, forKey: Constants.kMaxResults)
        defaults!.setObject(_summaryStyle, forKey: Constants.kSummaryStyle)
        defaults!.setObject(_sortStyle, forKey: Constants.kSortStyle)
        defaults!.setBool(_settingsPasscode!, forKey: Constants.kSettingsPasscode)
        
        defaults!.setObject(_searchIndexes, forKey: Constants.kSearchIndexes)
        defaults!.setObject(_addIndex, forKey: Constants.kAddIndex)
        
        defaults!.synchronize()
        
        performSegueWithIdentifier("SettingsSave", sender: self)
    }
    
    
    @IBAction func toggleSecureText(sender: UIButton) {
        self.apiKeyTextField.secureTextEntry = !self.apiKeyTextField.secureTextEntry
        if self.apiKeyTextField.secureTextEntry {
            sender.setImage(UIImage(named: "unlock"), forState: UIControlState.Normal)
        } else {
            sender.setImage(UIImage(named: "lock"), forState: UIControlState.Normal)
        }
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.apiKeyTextField.resignFirstResponder()
        return true
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {

        let identifier = segue.identifier
        if identifier == Constants.SelectIndexSearchSegue || identifier == Constants.SelectIndexAddSegue {
            
            readControls()
            
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SelectIndexTableViewController
            viewController.apiKey = _apiKey
            
            if identifier == Constants.SelectIndexSearchSegue {
                viewController.multiSelect = true
                if let si = _searchIndexes {
                    viewController.selectedIndexes = si.isEmpty ? [] : si.componentsSeparatedByString(",")
                }
            } else {
                viewController.multiSelect = false
                if let ai = _addIndex {
                    viewController.selectedIndexes = [ai]
                }
            }
        }
    }
    
    @IBAction func unwindFromSelection(segue : UIStoryboardSegue) {
        if segue.sourceViewController.isKindOfClass(SelectIndexTableViewController) {
            let vc = segue.sourceViewController as SelectIndexTableViewController
            
            if vc.multiSelect {
                _searchIndexes = vc.selectedIndexes.count > 0 ? ",".join(vc.selectedIndexes) : ""
            } else {
                _addIndex = vc.selectedIndexes.count > 0 ? vc.selectedIndexes[0] : ""
            }
        }
    }
    
    private func loadSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        _apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        _maxResults = defaults!.valueForKey(Constants.kMaxResults) as? Int
        _summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
        _sortStyle = defaults!.valueForKey(Constants.kSortStyle) as? String
        _searchIndexes = defaults!.valueForKey(Constants.kSearchIndexes) as? String
        _addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        _settingsPasscode = defaults!.valueForKey(Constants.kSettingsPasscode) as? Bool
        
        adjustControls()
    }
    
    private func adjustControls() {
        if let ak = _apiKey {
            apiKeyTextField.text = ak
        }
        
        maxResultButton.selectedSegmentIndex = 0
        summaryStyleButton.selectedSegmentIndex = 0
        sortStyleButton.selectedSegmentIndex = 0
        
        if let mr = _maxResults {
            switch (mr) {
            case 10: maxResultButton.selectedSegmentIndex = 1
            case 20: maxResultButton.selectedSegmentIndex = 2
            default : break
            }
        }
        
        if let summary = _summaryStyle {
            switch (summary.lowercaseString) {
            case Constants.SummaryStyleContext: summaryStyleButton.selectedSegmentIndex = 1
            case Constants.SummaryStyleConcept: summaryStyleButton.selectedSegmentIndex = 2
            default: break
            }
        }
        
        if let sort = _sortStyle {
            if sort.lowercaseString == Constants.SortStyleDate {
                sortStyleButton.selectedSegmentIndex = 1
            }
        }
        
        if let sp = _settingsPasscode {
            passcodeSwitch.setOn(sp, animated: true)
        }
        
    }
    
    private func readControls() {
        _apiKey = Utils.trim(apiKeyTextField.text)
        _maxResults = maxResultButton.titleForSegmentAtIndex(maxResultButton.selectedSegmentIndex)?.toInt()
        _summaryStyle = summaryStyleButton.titleForSegmentAtIndex(summaryStyleButton.selectedSegmentIndex)
        _sortStyle = sortStyleButton.titleForSegmentAtIndex(sortStyleButton.selectedSegmentIndex)
        _settingsPasscode = passcodeSwitch.on
    }
    

}
