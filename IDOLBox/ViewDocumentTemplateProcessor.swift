//
//  ViewDocumentTemplateProcessor.swift
//  IDOLBox
//
//  Created by TwoPi on 9/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

// Simple template processor for generating document preview
class ViewDocumentTemplateProcessor: NSObject {
    
    // The fields dictionary contains the fields and the values to be replaced in the template
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
