//
//  Utils.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 12/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

public class Utils: NSObject {
   
    public class func isUrl(str : String) -> Bool {
        let urlComps = str.componentsSeparatedByString("?")
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        let urlTest = NSPredicate(format: "SELF MATCHES %@", urlRegEx)
        return urlTest!.evaluateWithObject(urlComps[0])
    }
    
    public class func trim(str : String) -> String {
        return str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    public class func dateToString(date : NSDate) -> String? {
        return dateFormatter().stringFromDate(NSDate())
    }
    
    public class func stringToDate(str : String) -> NSDate? {
        
        return dateFormatter().dateFromString(str)
    }
    
    private class func dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return dateFormatter
    }
}
