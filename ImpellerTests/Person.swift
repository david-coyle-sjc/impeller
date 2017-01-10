//
//  Person.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import Impeller

struct Person: Storable {
    
    static let storedType = "Person"
    var metadata = Metadata()
    
    var name = "No Name"
    var age: Int? = nil
    var tags = [String]()
    
    init() {}
    
    init?(readingFrom repository:ReadRepository) {
        name = repository.read("name")!
        age = repository.read(optionalFor: "age")!
        tags = repository.read("tags")!
    }
    
    func write(in repository:WriteRepository) {
        repository.write(name, for: "name")
        repository.write(age, for: "age")
        repository.write(tags, for: "tags")
    }
    
    static func == (left: Person, right: Person) -> Bool {
        return left.name == right.name && left.age == right.age && left.tags == right.tags
    }
}
