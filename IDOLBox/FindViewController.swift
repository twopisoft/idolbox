//
//  FindViewController.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

class FindViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    private var _apiKey : String? = nil
    private var _searchIndexes : String? = nil
    private var _searchTerm : String? = nil
    
    private var _autoCompleteTableView : UITableView!
    private var _autoCompleteEntries : [String]!
    private var _pastEntries : [String]!
    
    private var _autoCompleteTableViewDelegate : AutoCompleteTableViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readSettings()
        registerForSettingsChange()
        setupAutoComplete()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 {
            self.searchButton.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
        
        hideViewAnimated(_autoCompleteTableView)
        
        if !(find(_pastEntries, searchTextField.text) != nil) {
            _pastEntries.append(searchTextField.text)
        }
        
        search(self)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if _pastEntries.count > 0 {
            showViewAnimated(_autoCompleteTableView)
        }
        
        var substring : NSString = searchTextField.text
        substring = substring.stringByReplacingCharactersInRange(range, withString: string)
        self.searchAutoCompleteEntriesWithSubstring(substring)
        return true
    }
    
    @IBAction func search(sender: AnyObject) {
        readControls()
        if !_searchTerm!.isEmpty {
            performSegueWithIdentifier(Constants.SearchResultSegue, sender: self)
        }
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
                viewController.selectedIndexes = si.isEmpty ? [Constants.DefaultSearchIndex] : si.componentsSeparatedByString(",")
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
    
    private func setupAutoComplete() {
        _pastEntries = []
        _autoCompleteEntries = []
        
        _autoCompleteTableView = UITableView(frame: CGRectMake(20, 125, 320, 120))
        _autoCompleteTableView.layer.borderWidth = 0.5
        _autoCompleteTableView.layer.cornerRadius = 10
        _autoCompleteTableView.layer.borderColor = UIColor.grayColor().CGColor
        
        _autoCompleteTableViewDelegate = AutoCompleteTableViewDelegate(autoCompleteEntries: self._autoCompleteEntries, searchTextField: self.searchTextField)
        
        _autoCompleteTableView.delegate = _autoCompleteTableViewDelegate
        _autoCompleteTableView.dataSource = _autoCompleteTableViewDelegate
        _autoCompleteTableView.scrollEnabled = true
        hideViewAnimated(_autoCompleteTableView)
        
        self.view.addSubview(_autoCompleteTableView)
    }
    
    private func searchAutoCompleteEntriesWithSubstring(substring : String) {
        _autoCompleteEntries.removeAll(keepCapacity: false)
        
        for entry in _pastEntries {
            let substringRange = entry.rangeOfString(substring, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)
            if substringRange != nil {
                _autoCompleteEntries.append(entry)
            }
        }
        _autoCompleteTableView.reloadData()
    }
    
    private func showViewAnimated(viewToShow : UIView) {
        UIView.animateWithDuration(0.5, animations: {
            viewToShow.alpha = 1
        })
    }
    
    private func hideViewAnimated(viewToHide : UIView) {
        UIView.animateWithDuration(0.5, animations: {
            viewToHide.alpha = 0
        })
    }
}

class AutoCompleteTableViewDelegate : NSObject, UITableViewDelegate, UITableViewDataSource {
    
    private var _autoCompleteEntries : [String]!
    private var _searchTextField : UITextField!
    
    init(autoCompleteEntries : [String], searchTextField : UITextField) {
        self._autoCompleteEntries = autoCompleteEntries
        self._searchTextField = searchTextField
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self._autoCompleteEntries.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("AutoCompleteTableViewCell") as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "AutoCompleteTableViewCell")
        }
        cell?.textLabel!.text = self._autoCompleteEntries[indexPath.row]
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        self._searchTextField.text = selectedCell?.textLabel?.text
    }
}
