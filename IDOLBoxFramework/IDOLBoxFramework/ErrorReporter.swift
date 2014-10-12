//
//  ErrorReporter.swift
//  IDOLBox
//
//  Created by TwoPi on 7/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

public class ErrorReporter: NSObject {
    
    // convenience functions for displaying fixed error messages
    public class func apiKeyNotSet(controller: UIViewController, handler : TypeAliases.AlertHanlder? = nil) {
        showAlertView(controller, title: "IDOLBox Error", message: "Please set the API Key", alertHandler: handler)
    }
    
    public class func addIndexNotSet(controller: UIViewController, handler : TypeAliases.AlertHanlder? = nil) {
        showAlertView(controller, title: "IDOLBox Error", message: "Please set the Add Index", alertHandler: handler)
    }
    
    // Main function for showing error alerts. If an alert handler is provided then execute it after user presses OK
    public class func showAlertView(controller: UIViewController, title : String?, message : String?, alertHandler ch: TypeAliases.AlertHanlder? = nil) {
        dispatch_async(dispatch_get_main_queue(), {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction!) in
                if let ah = ch {
                    dispatch_async(dispatch_get_main_queue(), {
                        alertController.dismissViewControllerAnimated(true, completion: nil)
                      ah()
                    })
                } else {
                alertController.dismissViewControllerAnimated(true, completion: nil)
                }
            }))
            controller.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    // Show error modal when NSError is provided
    public class func showErrorAlert(controller : UIViewController, error: NSError, handler : TypeAliases.AlertHanlder? = nil) {
        var title = ""
        var desc = ""
        if error.domain == Constants.IDOLService {
            title = "IDOLService Error"
            desc = error.userInfo!["Description"]! as String + "\nCode: \(error.code)"
        } else {
            title = "Operation Failed"
            desc = error.localizedDescription
        }
        
        showAlertView(controller, title: title, message: desc, alertHandler: handler)
    }
   
}
