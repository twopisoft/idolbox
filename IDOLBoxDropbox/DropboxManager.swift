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
import MobileCoreServices

class DropboxManager: NSObject {
    
    private let CLZ = "DropboxManager"
    
    typealias  LinkageCompleteHandler = (linked : Bool) -> ()
    
    typealias  FileInfo = (path:String,modtime:NSDate,size:Int64)
    
    // Base-64 encoded Dropbox Sync API Key and Secret
    private let dbAppKeyBase64    = "NjNhbmJmY3JqZTRldWZn"
    private let dbAppSecretBase64 = "NGdxMW9iajUzMWlxbXg3"
    
    private let dbDirectHost = "dl.dropboxusercontent.com"
    
    private var _apiKey : String!
    private var _addIndex : String!
    private var _dropboxLink : Bool!
    
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
        
        readSettings()
        registerForSettingsChange()
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
                NSLog("%@: Linking cancelled",CLZ)
                if _linkageCompleteHandler != nil {
                    _linkageCompleteHandler(linked: false)
                }
            } else if let _ = find(pathComps,"connect") {
                if let account = dbAccountManager().handleOpenURL(url) {
                    NSLog("%@: Dropbox account linked",CLZ)
                    
                    startObserving()
                    _linkageCompleteHandler(linked: true)
                    
                    return true
                }
            }
        }
        
        return false
    }
    
    func resumeLinkage() {
        resumeObserving()
    }
    
    func isLinked() -> Bool {
        if let _isLinked = _dropboxLink {
            return _isLinked
        }
        
        return false
    }
    
    func unlink() -> Bool {
        if let account = dbAccountManager().linkedAccount {
            NSLog("%@: Unlinking account",CLZ)
            
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
            } else {
                fs.removeObserver(self._changeObserver)
                
                fs.addObserver(self._changeObserver, forPathAndDescendants: DBPath.root(), block: { () -> Void in
                    self.findNeedsSyncFiles(account)
                    self.performSync(account)
                })
            }
            
            NSLog("%@: Started Observing",CLZ)
        }
    }
    
    private func resumeObserving() {
        if let account = dbAccountManager().linkedAccount {
            var fs = DBFilesystem.sharedFilesystem()
            
            if fs == nil {
                fs = DBFilesystem(account: account)
                DBFilesystem.setSharedFilesystem(fs)
            } else {
                fs.removeObserver(self._changeObserver)
            }
            
            fs.addObserver(self._changeObserver, forPathAndDescendants: DBPath.root(), block: { () -> Void in
                self.findNeedsSyncFiles(account)
                self.performSync(account)
            })
            
            NSLog("%@: Resumed Observing",CLZ)
        }
    }
    
    private func stopObserving() {
        if let account = dbAccountManager().linkedAccount {
            if let fs = DBFilesystem.sharedFilesystem() {
                DBFilesystem.sharedFilesystem().removeObserver(_changeObserver)
                NSLog("%@: Stopped Observing",CLZ)
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
        
        NSLog("%@: initFileData",CLZ)
        // cleanup before init
        removeFileData(account)
        
        let accountEntity = DropboxAccount(entity: NSEntityDescription.entityForName("DropboxAccount", inManagedObjectContext: self._managedObjectContext!)!, insertIntoManagedObjectContext: self._managedObjectContext)
        accountEntity.setValue(account.userId, forKey: "userId")
        
        for f in getFiles() {
            NSLog("%@: Adding file: %@",CLZ,f.path)
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
        NSLog("%@: fetchNeedsSyncFiles",CLZ)
        
        var freq = NSFetchRequest(entityName: "DropboxFile")
        freq.predicate = NSPredicate(format: "needsSync == %@ AND account.userId == %@", argumentArray: [true,account.userId])
        
        if let files = self._managedObjectContext?.executeFetchRequest(freq, error: nil) as? [DropboxFile] {
            return files
        }
        
        return nil
    }
    
    private func findNeedsSyncFiles(account : DBAccount) {
        NSLog("%@: findNeedsSyncFiles",CLZ)
        
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
                            
                            NSLog("%@: findNeedsSyncFiles: File %@ found both locally and remotely",CLZ,entry.path)
                            
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
                        
                        if let obj = mo as? DropboxFile {
                            NSLog("%@: findNeedsSyncFiles: File %@ marked for deletion",CLZ,obj.path)
                        }
                    }

                }
                
                var newFiles : [FileInfo] = []
                for (i,entry) in enumerate(dbFiles) {
                    if foundObjs[i] == nil {
                        NSLog("%@: findNeedsSyncFiles: File %@ added as new file",CLZ,entry.path)
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
        NSLog("%@: performSync",CLZ)
        
        if let files = fetchNeedsSyncFiles(account) {
            
            if files.count > 0 {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                    for f in files {
                        NSLog("%@: performSync: processing file %@",self.CLZ,f.path)
                        if f.needsDelete.boolValue {
                            NSLog("%@: Deleting file: %@",self.CLZ,f.path)
                            self._managedObjectContext?.deleteObject(f)
                            
                            if !f.shareLink.isEmpty {
                               self.deleteFromIndex(f.shareLink)
                            }
                        } else {
                            if f.shareLink.isEmpty {
                                if let sl = self.getShareLink(f.path) {
                                   f.setValue(sl, forKey: "shareLink")
                                    self.addToIndex(sl)
                                }
                            }
                            f.setValue(NSNumber(bool: false), forKey: "needsSync")
                            NSLog("%@: File Needs Sync: path=%@, modifiedTime=%@, shareLink=%@",self.CLZ,f.path,f.modifiedTime,f.shareLink)
                        }
                    }
                    
                    CoreDataHelper.sharedInstance.commit()
                })
            } else {
                NSLog("%@: No files to sync",CLZ)
            }
        }
    }
    
    private func getShareLink(path : String) -> String? {
        let fs = DBFilesystem.sharedFilesystem()
        let dbPathh = DBPath(string: path)
        var ferr : DBError? = nil
        if let shareLink = fs.fetchShareLinkForPath(dbPathh, shorten: false, error: &ferr) {
            let url = NSURL(string: shareLink)
            let shareUrl = NSURL(scheme: url!.scheme!, host: dbDirectHost, path: url!.path!)
            return shareUrl?.absoluteString
        } else {
            if ferr != nil {
                NSLog("%@: Error while getting shared link: %@",CLZ,ferr!.localizedDescription)
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
                if isTextType(f.path.stringValue()) {
                    fileInfo.append((path:f.path.stringValue(),modtime:f.modifiedTime,size:f.size))
                }
            }
        } else {
            NSLog("%@: File Error=%@",CLZ,ferr!)
        }
        
        return fileInfo
    }
    
    private func isTextType(path : String) -> Bool {
        if let uttype = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, path.pathExtension, nil) {
            return UTTypeConformsTo(uttype.takeUnretainedValue(), kUTTypeText) != 0 ||
                   UTTypeConformsTo(uttype.takeUnretainedValue(), kUTTypePDF) != 0
        }
        
        NSLog("%@: %@ is not supported for indexing",CLZ,path)
        return false
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
    
    private func addToIndex(url : String) {
        
        NSLog("%@: Adding %@ to index %@",CLZ,url,_addIndex)
        
        IDOLService.sharedInstance.addToIndexUrl(_apiKey, url: url, index: _addIndex) { (data, error) -> () in
            if error != nil {
                NSLog("%@: Error while adding url to Index: %@",self.CLZ,url)
            } else {
                NSLog("%@: Added url: %@ to index %@",self.CLZ,url,self._addIndex)
            }
        }
    }
    
    private func deleteFromIndex(url : String) {
        NSLog("%@: Deleting %@ from index %@",CLZ,url,_addIndex)
        
        IDOLService.sharedInstance.deleteFromIndex(_apiKey, reference: url, index: _addIndex) { (data, error) -> () in
            if error != nil {
                NSLog("%@: Error while deleting url from Index: %@",self.CLZ,url)
            } else {
                NSLog("%@: Deleted url: %@ from index %@",self.CLZ,url,self._addIndex)
            }
        }
    }
    
    private func readSettings() {
        let defaults = NSUserDefaults(suiteName: Constants.GroupContainerName)
        _apiKey = defaults!.valueForKey(Constants.kApiKey) as? String
        _addIndex = defaults!.valueForKey(Constants.kAddIndex) as? String
        _dropboxLink = defaults!.valueForKey(Constants.kDBAccountLinked) as? Bool
    }
    
    func settingsChanged(notification : NSNotification!) {
        readSettings()
    }
    
    private func registerForSettingsChange() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    private func urlScheme() -> String {
        return "db-" + dbAppKey()
    }
    
    
}
