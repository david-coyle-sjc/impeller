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
    
    init?(withRepository repository:SourceRepository) {
        child = repository.value(for: "child")!
        children = repository.values(for: "children")!
    }
    
    mutating func store(in repository:SinkRepository) {
        repository.store(&child, for: "child")
        repository.store(&children, for: "children")
    }
}
