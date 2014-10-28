//
//  DropboxAccount.swift
//  IDOLBox
//
//  Created by TwoPi on 28/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class DropboxAccount: NSManagedObject {

    @NSManaged var userId: String
    @NSManaged var files: NSSet

}
