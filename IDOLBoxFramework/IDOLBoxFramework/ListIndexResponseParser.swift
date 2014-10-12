//
//  ListIndexResponseParser.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

public class ListIndexResponseParser: NSObject {
 
    public class func parseResponse(data:NSData?) -> [TypeAliases.IndexTuple] {
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        let actions = json["actions"] as NSArray
        let result = actions[0]["result"] as NSDictionary
        var indexes : [TypeAliases.IndexTuple] = []
        let publicIndexes: AnyObject? = result["public_index"]
        let privateIndexes : AnyObject? = result["index"]
        
        if publicIndexes != nil {
            for pui in publicIndexes! as NSArray {
                let indexName = pui["index"] as String
                let indexType = pui["type"] as String
                indexes.append((name:indexName,flavor:indexType,isPublic:true,info:""))
            }
        }
        
        if privateIndexes != nil {
            for pri in privateIndexes! as NSArray {
                let indexName = pri["index"] as String
                let indexFlavor = pri["flavor"] as String
                let indexInfo = pri["description"]! != nil ?  pri["description"] as String : ""
                indexes.append((name:indexName,flavor:indexFlavor,isPublic:false,info:indexInfo))
            }
        }
        return indexes
    }
}
