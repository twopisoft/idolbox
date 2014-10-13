//
//  IdolBoxEntry.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 13/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

public class IdolBoxEntry: NSManagedObject {

    @NSManaged public var title: String
    @NSManaged public var reference: String
    @NSManaged public var summary: String
    @NSManaged public var moddate: NSDate
    @NSManaged public var content: String
    @NSManaged public var index: String

}
