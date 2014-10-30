//
//  DropboxFile.swift
//  IDOLBox
//
//  Created by TwoPi on 28/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class DropboxFile: NSManagedObject {

    @NSManaged var modifiedTime: NSDate
    @NSManaged var needsSync: NSNumber
    @NSManaged var needsDelete: NSNumber
    @NSManaged var path: String
    @NSManaged var shareLink: String
    @NSManaged var size: NSNumber
    @NSManaged var account: DropboxAccount

}
