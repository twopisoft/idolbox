//
//  ActivityProgressAlert.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 12/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

// Utility class for showing an alert with an activity indicator
public class ActivityProgressAlert: NSObject {
   
    public class func showAlertView(controller: UIViewController, title : String?, message : String?) -> UIViewController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        dispatch_async(dispatch_get_main_queue(), {
            var actInd = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
            actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            actInd.center = CGPointMake(130.5, 65.5)
            actInd.startAnimating()
            alertController.view.addSubview(actInd)
            controller.presentViewController(alertController, animated: true, completion: nil)
        })
        
        return alertController
    }
}
