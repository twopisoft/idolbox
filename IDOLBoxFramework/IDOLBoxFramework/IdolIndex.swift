//
//  IdolIndex.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 11/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

public class IdolIndex: NSManagedObject {

    @NSManaged public var flavor: String
    @NSManaged public var info: String
    @NSManaged public var isPublic: NSNumber
    @NSManaged public var name: String
    @NSManaged public var createdate: NSDate
    @NSManaged public var moddate: NSDate
    @NSManaged public var type: String

}
