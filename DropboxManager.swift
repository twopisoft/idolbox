//
//  DropboxManager.swift
//  IDOLBox
//
//  Created by TwoPi on 21/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import IDOLBoxFramework

class DropboxManager: NSObject {
    
    typealias  LinkageCompleteHandler = (linked : Bool) -> ()
    
    // Base-64 encoded Dropbox Sync API Key and Secret
    private let dbAppKeyBase64    = "NjNhbmJmY3JqZTRldWZn"
    private let dbAppSecretBase64 = "NGdxMW9iajUzMWlxbXg3"
    
    private let _initObserver = NSObject()
    private let _changeObserver = NSObject()
    
    private var _linkageCompleteHandler : LinkageCompleteHandler! = nil
    
    class var sharedInstance : DropboxManager {
        struct Singleton {
            static let instance = DropboxManager()
        }
        return Singleton.instance
    }
    
    private override init() {
        super.init()
    }
    
    func dbAppKey() -> String {
        return Utils.decodeBase64(dbAppKeyBase64)!
    }
    
    func dbAppSecret() -> String {
        return Utils.decodeBase64(dbAppSecretBase64)!
    }
    
    func link(controller : UIViewController, handler : LinkageCompleteHandler?) {
        _linkageCompleteHandler = handler
        dbAccountManager().linkFromController(controller)
    }
    
    func completeLinkage(url : NSURL) -> Bool {
        
        if url.scheme == urlScheme() {
            let pathComps = url.pathComponents as [String]
            if let _ = find(pathComps,"cancel") {
                NSLog("Linking cancelled")
                if _linkageCompleteHandler != nil {
                    _linkageCompleteHandler(linked: false)
                }
            } else if let _ = find(pathComps,"connect") {
                if let _ = dbAccountManager().handleOpenURL(url) {
                    NSLog("Dropbox account linked")
                    startObserving()
                    _linkageCompleteHandler(linked: true)
                    return true
                }
            }
        }
        
        return false
    }
    
    func unlink() -> Bool {
        if let account = dbAccountManager().linkedAccount {
            NSLog("Unlinking account")
            stopObserving()
            account.unlink()
            _linkageCompleteHandler = nil
            return true
        }
        return false
    }
    
    private func startObserving() {
        // Only start observing when there is a linked account
        if let account = dbAccountManager().linkedAccount {
            var fs = DBFilesystem.sharedFilesystem()
            
            if fs == nil {
                fs = DBFilesystem(account: account)
                DBFilesystem.setSharedFilesystem(fs)
                
                fs.addObserver(_initObserver, block: { () -> Void in
                    
                    if fs.completedFirstSync {
                        fs.removeObserver(self._initObserver)
                        
                        NSLog("completedFirstSync=%@",fs.completedFirstSync)
                        let path = DBPath.root()
                        var ferr : DBError? = nil
                        if let files = fs.listFolder(path, error: &ferr) as? [DBFileInfo] {
                            for f in files {
                                NSLog("path=%@, isFolder=%@, modtime=%@",f.path,f.isFolder,f.modifiedTime)
                            }
                        } else {
                            NSLog("File Error=%@",ferr!)
                        }
                        
                    }
                })
                fs.addObserver(_changeObserver, forPathAndDescendants: DBPath.root(), block: { () -> Void in
                    NSLog("Changes at IDOLBox")
                })
            }
            
            NSLog("Dropbox Manager: Started Observing")
        }
    }
    
    private func stopObserving() {
        if let account = dbAccountManager().linkedAccount {
            if let fs = DBFilesystem.sharedFilesystem() {
                DBFilesystem.sharedFilesystem().removeObserver(_changeObserver)
                NSLog("Dropbox Manager: Stopped Observing")
            }
        }
    }
    
    private func dbAccountManager() -> DBAccountManager {
        if let sm = DBAccountManager.sharedManager() {
            return sm
        }
        
        let _dbAccountManager = DBAccountManager(appKey: dbAppKey(), secret: dbAppSecret())
        DBAccountManager.setSharedManager(_dbAccountManager)
        return DBAccountManager.sharedManager()
    }
    
    private func urlScheme() -> String {
        return "db-" + dbAppKey()
    }
    
    
}
