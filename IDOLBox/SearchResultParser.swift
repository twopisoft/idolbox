//
//  SearchResultParser.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

class SearchResultParser: NSObject {
   
    class func parseResponse(data:NSData?) -> [DBHelper.ResultTuple] {
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        var searchResults : [DBHelper.ResultTuple] = []
        
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
                            var moddate : NSDate = NSDate()
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
                                    let dateFormatter = NSDateFormatter()
                                    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
                                    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                                    if let d = dateFormatter.dateFromString(_moddate[0] as String) {
                                        moddate = d
                                    }
                                }
                            }
                            
                            if let _summary = doc["summary"] as? String {
                                summary = _summary
                            }
                            
                            if let _content = doc["content"] as? String {
                                content = _content
                            }
                            
                            let entry : DBHelper.ResultTuple = (title,reference,weight,index,moddate,summary,content)
                            //NSLog("entry=\(entry)")
                            searchResults.append(entry)
                            
                        }
                    }
                }
            }
        }
        
        return searchResults
    }
}
