//
//  SearchResultParser.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import Foundation

// Parser for Search Reasults.
public class SearchResultParser: NSObject {
   
    // Parse the response data. Return a list of ResultTuples
    public class func parseResponse(data:NSData?) -> [TypeAliases.ResultTuple] {
        
        var error : NSError? = nil
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
        
        var searchResults : [TypeAliases.ResultTuple] = []
        
        if error == nil {
            //NSLog("json=%@",json)
            if let actions = json["actions"] as? NSArray {
                if actions.count > 0 {
                    if let result = actions[0]["result"] as? NSDictionary {
                        if let documents = result["documents"] as? NSArray {
                            NSLog("Found \(documents.count) results")
                            for doc in documents {
                                var title = ""
                                var reference = ""
                                var weight = 0.0
                                var index = ""
                                var moddate : NSDate = NSDate.distantFuture() as NSDate // Give a dummy date so that we can decide
                                                                                        // not to display the modified_date, for example
                                var summary = ""
                                var content = ""
                                
                                if let _reference = doc["reference"] as? String {
                                    reference = _reference
                                }
                                
                                if let _title = doc["title"] as? String {
                                    title = _title
                                } else {
                                    title = reference
                                }
                                
                                if let _weight = doc["weight"] as? Double {
                                    weight = _weight
                                }
                                
                                if let _index = doc["index"] as? String {
                                    index = _index
                                }
                                
                                if let _moddate = doc["modified_date"] as? NSArray {
                                    if _moddate.count > 0 {
                                        
                                        let md = _moddate[0] as String
                                        if let d = Utils.stringToDate(md) {
                                            moddate = d
                                        } else if let d = NSNumberFormatter().numberFromString(md) {
                                            moddate = NSDate(timeIntervalSince1970: d.doubleValue)
                                        }
                                    }
                                }
                                
                                if let _summary = doc["summary"] as? String {
                                    summary = _summary
                                }
                                
                                if let _content = doc["content"] as? String {
                                    content = _content
                                }
                                
                                let entry : TypeAliases.ResultTuple = (title,reference,weight,index,moddate,summary,content)
                                
                                searchResults.append(entry)
                                
                            }
                        }
                    }
                }
            }
        } else {
            NSLog("Error while parsing Search Result response: %@",error!)
        }
        
        return searchResults
    }
}
