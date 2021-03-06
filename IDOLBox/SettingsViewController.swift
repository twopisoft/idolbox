//
//  SettingsViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

// View Controller for Settings screen
class SettingsViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: Properties and Outlets
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var maxResultButton: UISegmentedControl!
    @IBOutlet weak var summaryStyleButton: UISegmentedControl!
    @IBOutlet weak var sortStyleButton: UISegmentedControl!
    @IBOutlet weak var passcodeSwitch: UISwitch!
    @IBOutlet weak var dropboxSwitch: UISwitch!
    
    private var _apiKey : String? = nil
    private var _maxResults : Int? = 5
    private var _summaryStyle : String? = Constants.SummaryStyleQuick
    private var _sortStyle : String? = Constants.SortStyleRelevance
    private var _settingsPasscode : Bool? = false
    private var _settingsPasscodeVal : String? = nil
    private var _searchIndexes : String? = nil
    private var _addIndex : String? = nil
    private var _dropboxLink : Bool? = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettings()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Make apikey field first responder for handling events
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            self.apiKeyTextField.becomeFirstResponder()
        }
    }

    // Save the settings
    @IBAction func save(sender: AnyObject) {
        readControls()
        var defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        defaults!.setObject(_apiKey, forKey: Constants.kApiKey)
        defaults!.setInteger(_maxResults!, forKey: Constants.kMaxResults)
        defaults!.setObject(_summaryStyle, forKey: Constants.kSummaryStyle)
        defaults!.setObject(_sortStyle, forKey: Constants.kSortStyle)
        defaults!.setBool(_settingsPasscode!, forKey: Constants.kSettingsPasscode)
        defaults!.setBool(_dropboxLink!, forKey: Constants.kDBAccountLinked)
        
        // Remove passcode value if user has switched it off
        if let sp = _settingsPasscode {
            if sp {
                defaults!.setObject(_settingsPasscodeVal, forKey: Constants.kSettingsPasscodeVal)
            } else {
                defaults!.setObject("", forKey: Constants.kSettingsPasscodeVal)
            }
        }
        
        defaults!.setObject(_searchIndexes, forKey: Constants.kSearchIndexes)
        defaults!.setObject(_addIndex, forKey: Constants.kAddIndex)
        
        defaults!.synchronize()
        
        performSegueWithIdentifier("SettingsSave", sender: self)
    }
    
    // Change text field secure entry attribute as well as the lock/unlock icon
    @IBAction func toggleSecureText(sender: UIButton) {
        self.apiKeyTextField.secureTextEntry = !self.apiKeyTextField.secureTextEntry
        if self.apiKeyTextField.secureTextEntry {
            sender.setImage(UIImage(named: "unlock"), forState: UIControlState.Normal)
        } else {
            sender.setImage(UIImage(named: "lock"), forState: UIControlState.Normal)
        }
    }
    
    
    // On return, hide the keyborad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.apiKeyTextField.resignFirstResponder()
        return true
    }

    @IBAction func toggleDropboxLink(sender: UISwitch) {
        var defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        
        if sender.on {
            if Utils.isNullOrEmpty(_apiKey) {
                ErrorReporter.apiKeyNotSet(self, handler: nil)
                self.dropboxSwitch.setOn(false, animated: true)
            } else if Utils.isNullOrEmpty(_addIndex) {
                ErrorReporter.addIndexNotSet(self, handler: nil)
                self.dropboxSwitch.setOn(false, animated: true)
            } else {
                // Force a save of properties
                defaults!.setObject(_apiKey, forKey: Constants.kApiKey)
                defaults!.setObject(_addIndex, forKey: Constants.kAddIndex)
                
                DropboxManager.sharedInstance.link(self, handler: { (linked) -> () in
                    if linked {
                        self._dropboxLink = true
                    } else {
                        // Linking cancelled
                        self._dropboxLink = false
                        dispatch_async(dispatch_get_main_queue(), {
                            self.dropboxSwitch.setOn(false, animated: true)  // Move the switch back to off position
                        })
                    }
                    
                    // Save this even if user has not saved it
                    defaults!.setBool(self._dropboxLink!, forKey: Constants.kDBAccountLinked)
                    
                })
            }
        } else {
            self._dropboxLink = false
            DropboxManager.sharedInstance.unlink()
            defaults!.setBool(self._dropboxLink!, forKey: Constants.kDBAccountLinked)
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {

        let identifier = segue.identifier
        if identifier == Constants.SelectIndexSearchSegue || identifier == Constants.SelectIndexAddSegue {
            
            readControls()
            
            let navController = segue.destinationViewController as UINavigationController
            var viewController = navController.topViewController as SelectIndexTableViewController
            viewController.apiKey = _apiKey
            
            // Moving to select index screen. Set the multiselect flag to true if selecting search indexes
            // otherwise false
            if identifier == Constants.SelectIndexSearchSegue {
                viewController.multiSelect = true
                if let si = _searchIndexes {
                    viewController.selectedIndexes = si.isEmpty ? [] : si.componentsSeparatedByString(",")
                }
            } else {
                viewController.multiSelect = false
                if let ai = _addIndex {
                    viewController.selectedIndexes = ai.isEmpty ? [] : [ai]
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
    
    // MARK: Helper methods
    // Read settings from user defaults
    private func loadSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        _apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        _maxResults = defaults!.valueForKey(Constants.kMaxResults) as? Int
        _summaryStyle = defaults!.valueForKey(Constants.kSummaryStyle) as? String
        _sortStyle = defaults!.valueForKey(Constants.kSortStyle) as? String
        _searchIndexes = defaults!.valueForKey(Constants.kSearchIndexes) as? String
        _addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        _settingsPasscode = defaults!.valueForKey(Constants.kSettingsPasscode) as? Bool
        _settingsPasscodeVal = defaults!.valueForKey(Constants.kSettingsPasscodeVal) as? String
        _dropboxLink = defaults!.valueForKey(Constants.kDBAccountLinked) as? Bool
        
        // Set defaults for some of the properties
        if _summaryStyle == nil {
            defaults!.setObject(Constants.SummaryStyleQuick, forKey: Constants.kSummaryStyle)
        }
        
        if _maxResults == nil {
           defaults!.setInteger(5, forKey: Constants.kMaxResults)
        }
        
        if _sortStyle == nil {
           defaults!.setObject(Constants.SortStyleRelevance, forKey: Constants.kSortStyle)
        }
        
        adjustControls()
    }
    
    // Update controls based on the settings values
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
        
        if let dl = _dropboxLink {
            dropboxSwitch.setOn(dl, animated: true)
        }
        
    }
    
    private func readControls() {
        _apiKey = Utils.trim(apiKeyTextField.text)
        _maxResults = maxResultButton.titleForSegmentAtIndex(maxResultButton.selectedSegmentIndex)?.toInt()
        _summaryStyle = summaryStyleButton.titleForSegmentAtIndex(summaryStyleButton.selectedSegmentIndex)
        _sortStyle = sortStyleButton.titleForSegmentAtIndex(sortStyleButton.selectedSegmentIndex)
        _settingsPasscode = passcodeSwitch.on
        _dropboxLink = dropboxSwitch.on
    }
    

}
