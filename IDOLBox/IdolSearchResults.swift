//
//  IdolSearchResults.swift
//  IDOLBox
//
//  Created by TwoPi on 8/10/14.
//  Copyright (c) 2014 TwoPi. All rights reserved.
//

import Foundation
import CoreData

class IdolSearchResults: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var reference: String
    @NSManaged var weight: NSNumber
    @NSManaged var index: String
    @NSManaged var summary: String
    @NSManaged var content: String

}
