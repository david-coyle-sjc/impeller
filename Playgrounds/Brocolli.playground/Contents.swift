//: Playground - noun: a place where people can play

import Cocoa

typealias UniqueIdentifier = String

protocol Storable {
    associatedtype StoreKeys
    var metadata: StorageMetadata { get set }
}

struct StorageProperty<KeyType, ValueType> {
    var value: ValueType
    let key: KeyType
    
    init(_ key: KeyType, value: ValueType) {
        self.value = value
        self.key = key
    }
}

struct StorageMetadata {
    var version: UInt64 = 0
    var timestamp = Date.timeIntervalSinceReferenceDate
    var uniqueIdentifier = UUID().uuidString
}

struct Person : Storable {
    
    var metadata = StorageMetadata()
    
    enum Key : String {
        case name
        case age
    }
    typealias StoreKeys = Key
    typealias Property<T> = StorageProperty<StoreKeys, T>

    let name = Property(.name, value: "Tom")
    let age = Property(.age, value: 64)

}

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
