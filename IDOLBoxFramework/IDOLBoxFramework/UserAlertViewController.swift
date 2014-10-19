//
//  UserAlertViewController.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 19/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit

public class UserAlertViewController: NSObject {
   
    public class func deleteAlertView(controller: UIViewController, title : String?, message : String?, alertHandler ch: TypeAliases.ChoiceAlertHandler? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (alert: UIAlertAction!) in
            dispatch_async(dispatch_get_main_queue(), {
                if let ah = ch {
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                    ah(choice: ChoiceAlertHandlerChoices.Delete)
                } else {
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue(), {
            controller.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}
