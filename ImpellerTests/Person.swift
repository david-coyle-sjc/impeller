//
//  Person.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Impeller

struct Person: Storable {
    
    static let storageType = "Person"
    var metadata = Metadata()
    
    var name = "No Name"
    var age: Int? = nil
    var tags = [String]()
    
    init() {}
    
    init?(withStorage storage:Storage) {
        name = storage.value(for: "name")!
        age = storage.value(for: "age")
        tags = storage.values(for: "tags")
    }
    
    func store(in storage:Storage) {
        storage.store(name, for: "name")
        storage.store(age, for: "age")
        storage.store(tags, for: "tags")
    }
    
    static func == (left: Person, right: Person) -> Bool {
        return left.name == right.name && left.age == right.age
    }
}
