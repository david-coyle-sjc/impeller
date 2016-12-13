//: Playground - noun: a place where people can play

import Cocoa

typealias UniqueIdentifier = String

protocol PropertyListable {
    func propertyList() -> Any
}

extension String : PropertyListable {
    func propertyList() -> Any {
        return self
    }
}

extension Int : PropertyListable {
    func propertyList() -> Any {
        return self
    }
}

struct StorableProperty<T:PropertyListable> {
    var value:T?

    init(_ value:T) {
        self.value = value
    }
    
    init(_ value:T? = nil) {
        self.value = nil
    }
}

prefix operator <-
prefix operator <-?
prefix func <- <T>(right: StorableProperty<T>) -> T {
    return right.value!
}
prefix func <-? <T>(right: StorableProperty<T>) -> T? {
    return right.value
}
prefix func <- <T>(right: T) -> StorableProperty<T> {
    return StorableProperty<T>(right)
}
prefix func <-? <T>(right: T?) -> StorableProperty<T> {
    return StorableProperty<T>(right)
}

protocol Storable {
    var metadata: Metadata { get set }
    func resolvedValue(forConflictWith newValue:Self) -> Self
}

extension Storable {
    mutating func store(_ value: PropertyListable) {
    }
    
    func resolvedValue(forConflictWith newValue:Self) -> Self {
        return self
    }
}

struct Metadata {
    var version: UInt64 = 0
    var timestamp = Date.timeIntervalSinceReferenceDate
    var uniqueIdentifier = UUID().uuidString
    init() {}
}

struct Person : Storable {
    var metadata = Metadata()
    var name = StorableProperty("No Name")
    var age = StorableProperty<Int>()
    init() {}
}

var person = Person()
<-person.name
person.name = <-"Tom"
var s = <-person.name

person.age = <-?13
let i = <-?person.age


/*
class Store {
    
    func save<T:Storable>(value:T) {
        let storeValue:T = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        
        var resolvedValue:T!
        if value.metadata.version == storeValue.metadata.version {
            // Store unchanged, so just save the new value directly
            resolvedValue = value
        }
        else {
            resolvedValue = value.resolvedValue(forConflictWith: storeValue)
        }
        
        // Update metadata
        resolvedValue.metadata.timestamp = Date.timeIntervalSinceReferenceDate
        resolvedValue.metadata.version = storeValue.metadata.version + 1
        
        // TODO: Save resolved value to disk
    }
    
    func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T {
        return Person() as! T
    }
}*/

