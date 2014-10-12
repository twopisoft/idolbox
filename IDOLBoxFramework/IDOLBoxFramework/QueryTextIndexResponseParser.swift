//
//  QueryTextIndexResponseParser.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 11/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

public class QueryTextIndexResponseParser: NSObject {
   
    public class func parseResponse(data:NSData?) -> [TypeAliases.ResultTuple] {
        
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        var searchResults : [TypeAliases.ResultTuple] = []
        
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
                            var dummydate = NSDate.distantFuture() as NSDate
                            
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
                            
                            let entry : TypeAliases.ResultTuple = (title,reference,weight,index,dummydate,"","")
                            searchResults.append(entry)
                            
                        }
                    }
                }
            }
        }
        
        return searchResults
    }

    
}
