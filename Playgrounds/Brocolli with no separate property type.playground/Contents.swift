//: Playground - noun: a place where people can play

import Cocoa

typealias UniqueIdentifier = String
typealias StorageVersion = UInt64

protocol ValueTreeTransformable {
    func valueTree() -> Any
    init?(withValueTree valueTree:Any)
}

protocol Storage : ValueTreeTransformable, Equatable {
    var metadata: Metadata { get set }
}

protocol Storable: Equatable {
    associatedtype StorageType: Storage
    var baseStorage: StorageType? { get set }
    var storage: StorageType { get set }
    func resolvedValue(forConflictWith newValue:Self) -> Self
}

extension Storable {
    func resolvedValue(forConflictWith newValue:Self) -> Self {
        return self
    }
}

func == <T:Storable>(left: T, right: T) -> Bool {
    return left.storage == right.storage
}

struct Metadata: ValueTreeTransformable, Equatable {
    var version: StorageVersion = 0
    var timestamp = Date.timeIntervalSinceReferenceDate
    var uniqueIdentifier: UniqueIdentifier = UUID().uuidString
    
    init(){}
    
    init?(withValueTree valueTree:Any) {
        if let d = valueTree as? [String:Any] {
            version = d["version"] as! StorageVersion
            timestamp = d["timestamp"] as! TimeInterval
            uniqueIdentifier = d["uniqueIdentifier"] as! UniqueIdentifier
        }
    }
    
    func valueTree() -> Any {
        return ["version":version, "timestamp":timestamp, "uniqueIdentifier":uniqueIdentifier]
    }
    
    static func == (left: Metadata, right: Metadata) -> Bool {
        return left.version == right.version && left.timestamp == right.timestamp && left.uniqueIdentifier == right.uniqueIdentifier
    }
}

struct PersonStorage: Storage {
    var metadata = Metadata()
    var name = "No Name"
    var age: Int? = nil
    
    init() {}
    
    init?(withValueTree valueTree:Any) {
        if let d = valueTree as? [String:Any] {
            metadata = Metadata(withValueTree: d["metadata"]!)!
            name = d["name"] as! String
            age = d["age"] as? Int
        }
        else {
            return nil
        }
    }
    
    func valueTree() -> Any {
        var d = ["metadata":metadata.valueTree(), "name":name]
        d["age"] = age
        return d
    }
    
    static func == (left: PersonStorage, right: PersonStorage) -> Bool {
        return left.name == right.name && left.age == right.age && left.metadata == right.metadata
    }
}

struct Person: Storable {
    typealias StorageType = PersonStorage
    var baseStorage: PersonStorage? = nil
    var storage = PersonStorage()
}

class Store {
    
    /// Resolves conflicts and saves, and sets the value on out to resolved value.
    func save<T:Storable>(_ value: inout T) {
        let storeValue:T? = fetchValue(identifiedBy: value.storage.metadata.uniqueIdentifier)
        
        var resolvedValue:T?
        var resolvedVersion:StorageVersion = 0
        var resolvedTimestamp = Date.timeIntervalSinceReferenceDate
        var saveResult = true
        if storeValue == nil {
            // First save
            resolvedValue = value
            resolvedVersion = 0
        }
        else if storeValue!.storage == value.storage {
            // Values unchanged from store. Don't save again.
            resolvedValue = storeValue!
            resolvedVersion = storeValue!.storage.metadata.version
            resolvedTimestamp = storeValue!.storage.metadata.timestamp
            saveResult = false
        }
        else if value.storage.metadata.version == storeValue!.storage.metadata.version {
            // Store has not changed since the base value was taken, so just save the new value directly
            resolvedValue = value
            resolvedVersion = value.storage.metadata.version + 1
        }
        else {
            resolvedValue = value.resolvedValue(forConflictWith: storeValue!)
            resolvedVersion = max(value.storage.metadata.version, storeValue!.storage.metadata.version) + 1
        }
        
        // Update metadata
        resolvedValue!.storage.metadata.timestamp = resolvedTimestamp
        resolvedValue!.storage.metadata.version = resolvedVersion
        resolvedValue!.baseStorage = resolvedValue!.storage
        
        // TODO: Save resolved value to disk
        if saveResult {
            
        }
        
        value = resolvedValue!
    }
    
    func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T? {
        return nil
    }
}


var person = Person()
person.storage.name = "Bob"
person.storage.age = 10

let store = Store()
store.save(&person)
person.storage.metadata.version

person.storage.age = 10
store.save(&person)

