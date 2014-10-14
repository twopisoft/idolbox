//
//  SettingsLoginHandler.swift
//  IDOLBox
//
//  Created by TwoPi on 14/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

class SettingsLoginHandler: NSObject {
    
    func showLogin(controller : UIViewController, passCode : String!, handler : (newPassCode: String!, cancelled : Bool) -> ()) {
        
        if passCode == nil || Utils.trim(passCode).isEmpty {
            setPasscode(controller, handler)
        } else {
            validatePasscode(controller, passCode: passCode, handler)
        }
    }
    
    private func setPasscode(controller : UIViewController, handler : (newPassCode: String!, cancelled : Bool) -> () ) {
        let alertController = UIAlertController(title: "Setting New Passocde", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Passcode"
            textField.secureTextEntry = true
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "Re-Enter Passcode"
            textField.secureTextEntry = true
        }
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action : UIAlertAction!) -> Void in
            let first = alertController.textFields?.first as? UITextField
            let second = alertController.textFields?.last as? UITextField
            if first?.text == second?.text {
                handler(newPassCode: first?.text, cancelled: false)
            } else {
                handler(newPassCode: nil, cancelled: false)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) { (action : UIAlertAction!) -> Void in
            handler(newPassCode: nil, cancelled: true)
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func validatePasscode(controller : UIViewController, passCode : String, handler : (newPassCode: String!, cancelled : Bool) -> () ) {
        let alertController = UIAlertController(title: "Enter Passocde", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter Passcode"
            textField.secureTextEntry = true
        }
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action : UIAlertAction!) -> Void in
            let first = alertController.textFields?.first as? UITextField
            handler(newPassCode: first?.text, cancelled: false)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) { (action : UIAlertAction!) -> Void in
            handler(newPassCode: nil, cancelled: true)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
   
}
