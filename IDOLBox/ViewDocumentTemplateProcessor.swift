//
//  ViewDocumentTemplateProcessor.swift
//  IDOLBox
//
//  Created by TwoPi on 9/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

class ViewDocumentTemplateProcessor: NSObject {
    
    class func processTemplate(fields : [String : String]) -> String {
        
        let filePath = NSBundle.mainBundle().pathForResource("ViewDocumentTemplate", ofType: "html")
        var template = NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding, error: nil)
        
        for f in fields.keys {
            let pat = "@\(f)@"
            template = template!.stringByReplacingOccurrencesOfString(pat, withString: fields[f]!)
        }
        
        return template!
    }
   
}
