//
//  IdolSearch.swift
//  IDOLBoxFramework
//
//  Created by TwoPi on 20/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

public class IdolSearch: NSManagedObject {

    @NSManaged public var term: String
    @NSManaged public var timestamp: NSDate
    @NSManaged public var indexes: String
    @NSManaged public var results: NSSet

}
