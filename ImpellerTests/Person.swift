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
    
    init?(withRepository repository:SourceRepository) {
        name = repository.value(for: "name")!
        age = repository.optionalValue(for: "age")!
        tags = repository.values(for: "tags")!
    }
    
    func store(in repository:SinkRepository) {
        repository.store(name, for: "name")
        repository.store(age, for: "age")
        repository.store(tags, for: "tags")
    }
    
    static func == (left: Person, right: Person) -> Bool {
        return left.name == right.name && left.age == right.age && left.tags == right.tags
    }
}
