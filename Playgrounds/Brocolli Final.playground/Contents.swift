
import Foundation

typealias UniqueIdentifier = String
typealias StorageVersion = UInt64

struct Metadata: Equatable {
    var version: StorageVersion = 0
    var timestamp = Date.timeIntervalSinceReferenceDate
    var uniqueIdentifier: UniqueIdentifier = UUID().uuidString
    
    init(){}
    
    init?(withStorage storage:Storage) {
        version = storage.value(for: "version")!
        timestamp = storage.value(for: "timestamp")!
        uniqueIdentifier = storage.value(for: "uniqueIdentifier")!
    }
    
    func store(in storage:Storage) {
        storage.store(version, for: "version")
        storage.store(timestamp, for: "timestamp")
        storage.store(uniqueIdentifier, for: "uniqueIdentifier")
    }
    
    static func == (left: Metadata, right: Metadata) -> Bool {
        return left.version == right.version && left.timestamp == right.timestamp && left.uniqueIdentifier == right.uniqueIdentifier
    }
}

protocol Storable: Hashable {
    static var storageType: String { get }
    var metadata: Metadata { get set }
    init?(withStorage storage:Storage)
    func store(in storage:Storage)
    func resolvedValue(forConflictWith newValue:Self) -> Self
}

struct AnyStorable<S:Storable> {
    var storable: S
    
    init(_ storable: S) {
        self.storable = storable
    }
}

extension Storable {
    func resolvedValue(forConflictWith newValue:Self) -> Self {
        return self
    }
    
    var hashValue: Int {
        return metadata.uniqueIdentifier.hash
    }
}

func == <T:Storable>(left: AnyStorable<T>, right: AnyStorable<T>) -> Bool {
    let store1 = MemoryStore()
    let store2 = MemoryStore()
    left.storable.store(in: store1)
    right.storable.store(in: store2)
    return store1 == store2
}

struct Person: Storable {
    
    static let storageType = "Person"

    var metadata = Metadata()
    var name = "No Name"
    var age: Int? = nil
    
    init() {}
    
    init?(withStorage storage:Storage) {
        name = storage.value(for: "name") ?? "No Name"
        age = storage.value(for: "age")
    }
    
    func store(in storage:Storage) {
        storage.store(name, for: "name")
        storage.store(age, for: "age")
    }
    
    static func == (left: Person, right: Person) -> Bool {
        return left.name == right.name && left.age == right.age && left.metadata == right.metadata
    }
}

protocol Storage {
    func value<T:Equatable>(for key:String) -> T?
    func store<T:Equatable>(_ value:T, for key:String)
    func store<T:Equatable>(_ value:T?, for key:String)
}

class MemoryStore: Storage, Equatable {
    
    private var storageDictionary = [String:AnyEquatable]()
    private var currentStorageType = ""
    private var currentUniqueIdentifier = ""
    
    private func storeKey(forCurrentValueKey key:String) -> String {
        return "\(currentStorageType)_\(currentUniqueIdentifier)_\(key)"
    }
    
    func value<T:Equatable>(for key:String) -> T? {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        return storageDictionary[storeKey]?.equatable as? T
    }
    
    func store<T:Equatable>(_ value:T, for key:String) {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        storageDictionary[storeKey] = AnyEquatable(value)
    }
    
    func store<T:Equatable>(_ value:T?, for key:String) {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        storageDictionary[storeKey] = value != nil ? AnyEquatable(value!) : nil
    }
    
    /// Resolves conflicts and saves, and sets the value on out to resolved value.
    func save<T:Storable>(_ value: inout T) {
        currentUniqueIdentifier = value.metadata.uniqueIdentifier
        currentStorageType = T.storageType
        
        let storeValue:T? = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        
        var resolvedValue:T
        var resolvedVersion:StorageVersion = 0
        var resolvedTimestamp = Date.timeIntervalSinceReferenceDate
        var saveResult = true
        if storeValue == nil {
            // First save
            resolvedValue = value
            resolvedVersion = 0
        }
       else if storeValue! == value {
            // Values unchanged from store. Don't save again.
            resolvedValue = storeValue!
            resolvedVersion = storeValue!.metadata.version
            resolvedTimestamp = storeValue!.metadata.timestamp
            saveResult = false
        }
        else if value.metadata.version == storeValue!.metadata.version {
            // Store has not changed since the base value was taken, so just save the new value directly
            resolvedValue = value
            resolvedVersion = value.metadata.version + 1
        }
        else {
            resolvedValue = value.resolvedValue(forConflictWith: storeValue!)
            resolvedVersion = max(value.metadata.version, storeValue!.metadata.version) + 1
        }
   
        // Update metadata
        resolvedValue.metadata.timestamp = resolvedTimestamp
        resolvedValue.metadata.version = resolvedVersion
        
        // TODO: Save resolved value to disk
        if saveResult {
        }
        
        value = resolvedValue
    }
    
    func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T? {
        return nil
    }
    
    static func == (left: MemoryStore, right: MemoryStore) -> Bool {
        return left.storageDictionary == right.storageDictionary
    }
}

struct AnyEquatable: Equatable {
    let equatable: Any
    let equals: (Any) -> Bool
    
    init<E: Equatable>(_ equatable: E) {
        self.equatable = equatable
        self.equals = { (($0 as? E) == equatable) }
    }
}


func ==(lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
    return lhs.equals(rhs.equatable)
}


var person = Person()
person.name = "Bob"
person.age = 10


let store = MemoryStore()
store.save(&person)
person.metadata.version

person.age = 10


