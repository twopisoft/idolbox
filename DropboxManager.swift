//
//  DropboxManager.swift
//  IDOLBox
//
//  Created by TwoPi on 21/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import UIKit
import CoreData
import IDOLBoxFramework

class DropboxManager: NSObject {
    
    typealias  LinkageCompleteHandler = (linked : Bool) -> ()
    
    typealias  FileInfo = (path:String,modtime:NSDate,size:Int64)
    
    // Base-64 encoded Dropbox Sync API Key and Secret
    private let dbAppKeyBase64    = "NjNhbmJmY3JqZTRldWZn"
    private let dbAppSecretBase64 = "NGdxMW9iajUzMWlxbXg3"
    
    private let _initObserver = NSObject()
    private let _changeObserver = NSObject()
    
    private var _linkageCompleteHandler : LinkageCompleteHandler! = nil
    
    private lazy var _managedObjectContext: NSManagedObjectContext? = {
        return CoreDataHelper.sharedInstance.managedObjectContext
    }()
    
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
                if let account = dbAccountManager().handleOpenURL(url) {
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
            removeFileData(account)
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
                
                fs.addObserver(self._initObserver, block: { () -> Void in
                    if fs.completedFirstSync {
                        fs.removeObserver(self._initObserver)
                        
                        self.initFileData(account)
                        self.performSync(account)
                        
                        fs.addObserver(self._changeObserver, forPathAndDescendants: DBPath.root(), block: { () -> Void in
                            self.findNeedsSyncFiles(account)
                            self.performSync(account)
                        })
                    }
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
    
    private func initFileData(account : DBAccount) {
        
        NSLog("initFileData")
        // cleanup before init
        removeFileData(account)
        
        let accountEntity = DropboxAccount(entity: NSEntityDescription.entityForName("DropboxAccount", inManagedObjectContext: self._managedObjectContext!)!, insertIntoManagedObjectContext: self._managedObjectContext)
        accountEntity.setValue(account.userId, forKey: "userId")
        
        for f in getFiles() {
            NSLog("Adding file: %@",f.path)
            addFileObject(f, accountEntity: accountEntity)
        }
    
        CoreDataHelper.sharedInstance.commit()

    }
    
    private func removeFileData(account : DBAccount) {
        var freq = NSFetchRequest(entityName: "DropboxAccount")
        freq.predicate = NSPredicate(format: "userId == %@", argumentArray: [account.userId])
        if let res = self._managedObjectContext?.executeFetchRequest(freq, error: nil) {
            if res.count > 0 {
                if let user = res[0] as? NSManagedObject {
                    self._managedObjectContext?.deleteObject(user)
                    CoreDataHelper.sharedInstance.commit()
                }
            }
        }
    }
    
    private func hasFileData(account : DBAccount) -> Bool {
        var freq = NSFetchRequest(entityName: "DropboxAccount")
        freq.predicate = NSPredicate(format: "userId == %@", argumentArray: [account.userId])
        if let res = self._managedObjectContext?.executeFetchRequest(freq, error: nil) {
            return res.count > 0
        }
        return false
    }
    
    private func fetchNeedsSyncFiles(account : DBAccount) -> [DropboxFile]? {
        NSLog("fetchNeedsSyncFiles")
        
        var freq = NSFetchRequest(entityName: "DropboxAccount")
        freq.predicate = NSPredicate(format: "userId == %@", argumentArray: [account.userId])
        
        if let res = self._managedObjectContext?.executeFetchRequest(freq, error: nil) {
            var needSyncFiles : [DropboxFile] = []
            if res.count > 0 {
                if let files = (res[0] as? DropboxAccount)?.files {
                    for f in files {
                        if (f as DropboxFile).needsSync.boolValue {
                            needSyncFiles.append(f as DropboxFile)
                        }
                    }
                    return needSyncFiles
                }
            }
        }
        
        return nil
    }
    
    private func findNeedsSyncFiles(account : DBAccount) {
        NSLog("findNeedsSyncFiles")
        
        let dbFiles = getFiles()
        
        var freq = NSFetchRequest(entityName: "DropboxAccount")
        freq.predicate = NSPredicate(format: "userId == %@", argumentArray: [account.userId])
        if let accounts = self._managedObjectContext?.executeFetchRequest(freq, error: nil) as? [DropboxAccount] {
            
            if accounts.count > 0 {
            
                let accountEntity = accounts[0]
                
                var foundObjs : [Int:FileInfo] = [:]
                
                for mo in accountEntity.files {
                    var found = false
                    
                    for (i,entry) in enumerate(dbFiles) {
                        if (mo.path == entry.path) {
                            found = true
                            foundObjs[i] = entry
                            
                            if ((mo.valueForKey("modifiedTime") as NSDate).compare(entry.modtime) == NSComparisonResult.OrderedDescending) {
                                mo.setValue(NSNumber(bool: true), forKey: "needsSync")
                                mo.setValue(NSNumber(longLong: entry.size), forKey: "size")
                                mo.setValue(entry.modtime, forKey: "modifiedTime")
                            }
                        }
                    }
                    
                    if !found {
                        mo.setValue(NSNumber(bool: true), forKey: "needsSync")
                        mo.setValue(NSNumber(bool: true), forKey: "needsDelete")
                    }

                }
                
                var newFiles : [FileInfo] = []
                for (i,entry) in enumerate(dbFiles) {
                    if foundObjs[i] == nil {
                        newFiles.append(entry)
                    }
                }
                
                for f in newFiles {
                    addFileObject(f, accountEntity: accountEntity)
                }
                
                CoreDataHelper.sharedInstance.commit()
            }
        }
    }
    
    private func performSync(account : DBAccount) {
        NSLog("performSync")
        
        if let files = fetchNeedsSyncFiles(account) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                for f in files {
                    if f.needsDelete.boolValue {
                        NSLog("Deleting file: %@",f.path)
                        self._managedObjectContext?.deleteObject(f)
                    } else {
                        if f.shareLink.isEmpty {
                            if let sl = self.getShareLink(f.path) {
                               f.setValue(sl, forKey: "shareLink")
                            }
                        }
                        f.setValue(NSNumber(bool: false), forKey: "needsSync")
                        NSLog("File Needs Sync: path=%@, modifiedTime=%@, shareLink=%@",f.path,f.modifiedTime,f.shareLink)
                    }
                }
                
                CoreDataHelper.sharedInstance.commit()
            })
        }
    }
    
    private func getShareLink(path : String) -> String? {
        let fs = DBFilesystem.sharedFilesystem()
        let dbPathh = DBPath(string: path)
        var ferr : DBError? = nil
        if let shareLink = fs.fetchShareLinkForPath(dbPathh, shorten: true, error: &ferr) {
            return shareLink
        } else {
            if ferr != nil {
                NSLog("Error while getting shared link: %@",ferr!.localizedDescription)
            }
        }
        return nil
    }
    
    private func getFiles() -> [FileInfo] {
        var fileInfo : [FileInfo] = []
        
        let fs = DBFilesystem.sharedFilesystem()
        let path = DBPath.root()
        var ferr : DBError? = nil
        if let files = fs.listFolder(path, error: &ferr) as? [DBFileInfo] {
            for f in files {
                //NSLog("path=%@, isFolder=%@, modtime=%@",f.path,f.isFolder,f.modifiedTime)
                fileInfo.append((path:f.path.stringValue(),modtime:f.modifiedTime,size:f.size))
            }
        } else {
            NSLog("File Error=%@",ferr!)
        }
        
        return fileInfo
    }
    
    private func addFileObject(fileInfo : FileInfo, accountEntity : DropboxAccount) -> DropboxFile {
        let fileEntity = DropboxFile(entity: NSEntityDescription.entityForName("DropboxFile", inManagedObjectContext: self._managedObjectContext!)!, insertIntoManagedObjectContext: self._managedObjectContext)
        fileEntity.setValue(fileInfo.path, forKey: "path")
        fileEntity.setValue(fileInfo.modtime, forKey: "modifiedTime")
        fileEntity.setValue(NSNumber(longLong: fileInfo.size), forKey: "size")
        fileEntity.setValue("", forKey: "shareLink")
        fileEntity.setValue(NSNumber(bool: true), forKey: "needsSync")
        fileEntity.setValue(NSNumber(bool: false), forKey: "needsDelete")
        fileEntity.setValue(accountEntity, forKey: "account")
        
        var fileRel = accountEntity.valueForKey("files") as NSMutableSet
        fileRel.addObject(fileEntity)
        
        return fileEntity
    }
    
    private func urlScheme() -> String {
        return "db-" + dbAppKey()
    }
    
    
}
