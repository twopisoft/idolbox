//
//  Utils.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 12/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

// Class for Utility methods
public class Utils: NSObject {
   
    // Checks if a string is a https(s) url. Note that we only consider the url scheme.
    public class func isUrl(str : String) -> Bool {
        if let url = NSURL(string: str) {
            let scheme = url.scheme?.lowercaseString
            return scheme == "http" || scheme == "https"
        }
        return false
    }
    
    // String trim.
    public class func trim(str : String) -> String {
        return str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    public class func isNullOrEmpty(str : String!) -> Bool {
        if str == nil || trim(str).isEmpty {
            return true
        }
        return false
    }
    
    // Date to String based on the yyyy-MM-ddTHH:mm:ssZ format
    public class func dateToString(date : NSDate) -> String? {
        return dateFormatter().stringFromDate(date)
    }
    
    // String to Date based on the yyyy-MM-ddTHH:mm:ssZ format
    public class func stringToDate(str : String) -> NSDate? {
        return dateFormatter().dateFromString(str)
    }
    
    public class func decodeBase64(str : String) -> String? {
        let data = NSData(base64EncodedString: str, options: NSDataBase64DecodingOptions.allZeros)
        return NSString(data: data!, encoding: NSUTF8StringEncoding)
    }
    
    public class func jsonStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string
                }
            }
        }
        return ""
    }
    
    private class func dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return dateFormatter
    }
}
