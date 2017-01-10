//
//  Parent.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Impeller

struct Parent: Storable {
    
    static let storedType = "Parent"
    var metadata = Metadata()
    
    var child = Child()
    var children = [Child]()

    init() {}
    
    init?(readingFrom repository:ReadRepository) {
        child = repository.read("child")!
        children = repository.read("children")!
    }
    
    mutating func write(in repository:WriteRepository) {
        repository.write(&child, for: "child")
        repository.write(&children, for: "children")
    }
}
