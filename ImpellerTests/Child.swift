//
//  Child.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Impeller

struct Child: Storable {
    
    static let storedType = "Child"
    var metadata = Metadata()
    
    var age = 0
        
    init() {}
    
    init?(readingFrom repository:ReadRepository) {
        age = repository.read("age")!
    }
    
    mutating func write(in repository:WriteRepository) {
        repository.write(age, for: "age")
    }
    
    static func == (left: Child, right: Child) -> Bool {
        return left.age == right.age
    }
    
    // Take child with newest timestamp
    func resolvedValue(forConflictWith newValue:Storable, context: Any? = nil) -> Child {
        return newValue.metadata.timestamp > metadata.timestamp ? newValue as! Child : self
    }
}
