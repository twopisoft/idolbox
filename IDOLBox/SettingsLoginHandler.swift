//
//  SettingsLoginHandler.swift
//  IDOLBox
//
//  Created by TwoPi on 14/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

// Utility class for handling settings page passcode based logins
class SettingsLoginHandler: NSObject {
    
    // Validate or set a passcode
    class func validate(controller : UIViewController, passcodeFlag : Bool?, var passCodeVal : String?) {
        // If passcode was set
        if let pc = passcodeFlag {
            if pc {
                let login = SettingsLoginHandler()
                // Show the passcode prompt
                login.showLogin(controller, passCode: passCodeVal, handler: { (newPassCode, cancelled) -> () in
                    // User pressed OK
                    if !cancelled {
                        // If previously passcode was not set and
                        if passCodeVal == nil || passCodeVal!.isEmpty {
                            // New passcode is also nil, means that there was an error at passcode setting
                            if newPassCode == nil {
                                ErrorReporter.showAlertView(controller, title: "Passcode was not set", message: "Values did not match", alertHandler: nil)
                            } else {
                                // Otherwise set the passcode in user defaults and navigate to settings page
                                passCodeVal = newPassCode
                                var defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
                                defaults!.setObject(passCodeVal, forKey: Constants.kSettingsPasscodeVal)
                                controller.performSegueWithIdentifier("Settings", sender: controller)
                            }
                        } else {
                            // Passcode was previous set. Check if user entered correct value
                            if passCodeVal! != newPassCode {
                                ErrorReporter.showAlertView(controller, title: "Passcode Incorrect", message: nil, alertHandler: nil)
                            } else {
                                controller.performSegueWithIdentifier("Settings", sender: controller)
                            }
                        }
                    }
                })
            } else {
                // Passcode is not enabled
                controller.performSegueWithIdentifier("Settings", sender: controller)
            }
        } else {
            // Passcode is not enabled
            controller.performSegueWithIdentifier("Settings", sender: controller)
        }
    }
    
    // Show passcode setting or login propmpt according to whether the old value
    func showLogin(controller : UIViewController, passCode : String!, handler : (newPassCode: String!, cancelled : Bool) -> ()) {
        
        if passCode == nil || Utils.trim(passCode).isEmpty {
            setPasscode(controller, handler)
        } else {
            validatePasscode(controller, passCode: passCode, handler)
        }
    }
    
    // Set a new passcode
    private func setPasscode(controller : UIViewController, handler : (newPassCode: String!, cancelled : Bool) -> () ) {
        
        // Create alert controller and text fields
        let alertController = UIAlertController(title: "Setting New Passcode", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
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
            
            // Disallow setting of empty passcode. Min length is atleast one character
            if !Utils.trim(first!.text).isEmpty && first?.text == second?.text {
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
    
    // Validate a passcode
    private func validatePasscode(controller : UIViewController, passCode : String, handler : (newPassCode: String!, cancelled : Bool) -> () ) {
        // Create alert controller and text fields
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
