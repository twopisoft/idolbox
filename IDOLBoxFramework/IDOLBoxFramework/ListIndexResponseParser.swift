//
//  ListIndexResponseParser.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

// Parser for List Index API response
public class ListIndexResponseParser: NSObject {
 
    // Parse the response and return list of Index Tuples
    public class func parseResponse(data:NSData?) -> [TypeAliases.IndexTuple] {
        
        var error : NSError? = nil
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
        
        var indexes : [TypeAliases.IndexTuple] = []
        
        if error == nil {
        
            if let actions = json["actions"] as? NSArray {
                
                if actions.count > 0 {
                        if let result = actions[0]["result"] as? NSDictionary {
                        
                        if let publicIndexes = result["public_index"] as? NSArray {
                            for pui in publicIndexes as NSArray {
                                let indexName = pui["index"] as String
                                let indexType = pui["type"] as String
                                indexes.append((name:indexName,flavor:indexType,isPublic:true,info:""))
                            }
                        }
                        
                        if let privateIndexes = result["index"] as? NSArray {
                            for pri in privateIndexes as NSArray {
                                let indexName = pri["index"] as String
                                let indexFlavor = pri["flavor"] as String
                                let indexInfo = pri["description"]! != nil ?  pri["description"] as String : ""
                                indexes.append((name:indexName,flavor:indexFlavor,isPublic:false,info:indexInfo))
                            }
                        }
                    }
                }
            }
            
        } else {
            NSLog("Error while parsing List Index response: %@", error!)
        }
        
        return indexes
    }
}
