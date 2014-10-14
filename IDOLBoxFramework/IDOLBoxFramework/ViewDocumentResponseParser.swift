//
//  ViewDocumentResponseParser.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 12/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

// Parser for View Document API response
public class ViewDocumentResponseParser: NSObject {
   
    // Parse the reply and return a string
    public class func parseResponse(data:NSData?) -> String {
        var error : NSError? = nil
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
        
        var docStr : NSString! = ""
        
        if error == nil {
            if let actions = json["actions"] as? NSArray {
                if actions.count > 0 {
                    if let document = actions[0]["result"] as? NSString {
                        docStr = document
                    }
                }
            }
        } else {
            NSLog("Error while parsing View Document response: %@",error!)
        }
        
        return docStr
    }
}
