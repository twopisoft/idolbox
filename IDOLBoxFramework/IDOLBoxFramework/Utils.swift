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
    
    // Date to String based on the yyyy-MM-ddTHH:mm:ssZ format
    public class func dateToString(date : NSDate) -> String? {
        return dateFormatter().stringFromDate(NSDate())
    }
    
    // String to Date based on the yyyy-MM-ddTHH:mm:ssZ format
    public class func stringToDate(str : String) -> NSDate? {
        return dateFormatter().dateFromString(str)
    }
    
    public class func decodeBase64(str : String) -> String? {
        let data = NSData(base64EncodedString: str, options: NSDataBase64DecodingOptions.allZeros)
        return NSString(data: data!, encoding: NSUTF8StringEncoding)
    }
    
    private class func dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return dateFormatter
    }
}
