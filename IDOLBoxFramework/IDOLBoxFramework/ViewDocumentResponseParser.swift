//
//  ViewDocumentResponseParser.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 12/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

public class ViewDocumentResponseParser: NSObject {
   
    public class func parseResponse(data:NSData?) -> String {
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        var docStr : NSString! = ""
        
        if let actions = json["actions"] as? NSArray {
            if actions.count > 0 {
                if let document = actions[0]["result"] as? NSString {
                    docStr = document
                }
            }
        }
        
        return docStr
    }
}
