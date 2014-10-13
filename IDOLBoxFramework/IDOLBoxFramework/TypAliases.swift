//
//  TypAliases.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 11/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

public struct TypeAliases {
    
    // Tuple for Index Info
    public typealias IndexTuple = (name:String,flavor:String,isPublic:Bool,info:String)
    
    // Tuple for Search Result
    public typealias ResultTuple = (title:String,reference:String,weight:Double,index:String,moddate:NSDate,summary:String,content:String)
    
    // Tuple for Query Text Index result
    public typealias QueryResult = (title:String, reference:String, weight:Double, index:String)
    
    // Tuple for File meta info
    public typealias FileMeta          = (path:String,name:String,isDir:Bool)
    
    // Typealiases for response handlers used by IDOLService
    public typealias ResponseHandler   = (data:NSData?, error:NSError?) -> ()
    public typealias JobRespHandler    = (jobId:String?, jobError:NSError?) -> ()
    
    // Alert View Handler
    public typealias AlertHanlder = () -> ()
    
    // Cell Config Handler for FetchResultsControllerDelegate
    public typealias ConfigHandler = (controller: NSFetchedResultsController, cell : UITableViewCell, indexPath: NSIndexPath) -> UITableViewCell
}