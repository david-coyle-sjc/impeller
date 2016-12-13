//: Playground - noun: a place where people can play

import Cocoa

typealias UniqueIdentifier = String

protocol Keyed {
    var key: String { get }
}

protocol Storable {
    associatedtype StorableProperty: Keyed
    var storage: Storage<StorableProperty> { get set }
    mutating func store(_ value: StorableProperty)
}

extension Storable {
    mutating func store(_ value: StorableProperty) {
        storage.propertiesByKey[value.key] = value
    }
}

struct Storage<PropertyType> {
    var version: UInt64 = 0
    var timestamp = Date.timeIntervalSinceReferenceDate
    var uniqueIdentifier = UUID().uuidString
    var propertiesByKey = [String: PropertyType]()
    init() {}
}

struct Person : Storable {
    
    var storage = Storage<StorableProperty>()
    
    enum Property : Keyed {
        case name(String)
        case age(Int)
        
        var key: String {
            return ""
        }
    }
    typealias StorableProperty = Property
}

var person = Person()
person.store(.name("Tom"))


/*
class Store {
    
    func saveValue<T:Storable>(value:T, resolvingConflictWith handler:((T, T) -> T)? ) {
        let storeValue:T = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        
        var resolvedValue:T!
        if value.metadata.version == storeValue.metadata.version {
            // Store unchanged, so just save the new value directly
            resolvedValue = value
        }
        else {
            // Conflict. There have been saves since we fetched this value.
            let values = [storeValue, value]
            let sortedValues = values.sorted { $0.metadata.timestamp < $1.metadata.timestamp }
            if let handler = handler {
                resolvedValue = handler(sortedValues[0], sortedValues[1])
            }
            else {
                resolvedValue = sortedValues[1] // Take most recent
            }
        }
        
        // Update metadata
        resolvedValue.metadata.timestamp = Date.timeIntervalSinceReferenceDate
        resolvedValue.metadata.version = storeValue.metadata.version + 1
        
        // TODO: Save resolved value to disk
    }
    
    func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T {
        return Person() as! T
    }
}
 */
