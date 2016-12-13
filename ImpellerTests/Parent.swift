//
//  Parent.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Impeller

struct Parent: Storable {
    
    static let storageType = "Parent"
    var metadata = Metadata()
    
    var child = Child()
    var children = [Child]()

    init() {}
    
    init?(withStorage storage:Storage) {
        child = storage.value(for: "child")!
        children = storage.values(for: "children")
    }
    
    mutating func store(in storage:Storage) {
        storage.store(&child, for: "child")
        storage.store(&children, for: "children")
    }
    
    static func == (left: Parent, right: Parent) -> Bool {
        return left.child == right.child
    }
}
