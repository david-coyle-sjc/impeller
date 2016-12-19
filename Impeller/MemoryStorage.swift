//
//  MemoryStorage
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

private let metadataTypeSuffix = "__Metadata"


fileprivate struct TimestampCursor: Cursor {
    private (set) var timestamp: TimeInterval
    
    var data: Data {
        get {
            var t = timestamp
            return Data(buffer: UnsafeBufferPointer(start: &t, count: 1))
        }
        set {
            timestamp = data.withUnsafeBytes { $0.pointee }
        }
    }
    
    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
    }
}


public class MemoryStorage: Storage, Exchangable {
    
    public var uniqueIdentifier: UniqueIdentifier = uuid()
    private var keyValueStore = [String:Any]()
    private var currentTreeReference = ValueTreeReference(uniqueIdentifier: "", storageType: "")
    private var identifiersOfUnchanged = Set<UniqueIdentifier>()
    
    private class func storeKey(for reference: ValueTreeReference, key: String) -> String {
        return "\(reference.storageType)/\(reference.uniqueIdentifier)/\(key)"
    }
    
    private func storeKey(forCurrentValueKey key:String) -> String {
        return MemoryStorage.storeKey(for: currentTreeReference, key: key)
    }
    
    public func value<T:StorablePrimitive>(for key:String) -> T? {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        if let value = keyValueStore[storeKey] {
            return T(withStorableValue: value)
        }
        else {
            return nil
        }
    }
    
    public func values<T:StorablePrimitive>(for key:String) -> [T] {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        return keyValueStore[storeKey] as? [T] ?? []
    }
    
    public func value<T:Storable>(for key:String) -> T? {
        let storeKey = self.storeKey(forCurrentValueKey: key)
    
        guard let reference = keyValueStore[storeKey] as? ValueTreeReference else {
            return nil
        }
        
        return fetchValue(identifiedBy: reference.uniqueIdentifier)
    }
    
    public func values<T:Storable>(for key:String) -> [T] {
        let storeKey = self.storeKey(forCurrentValueKey: key)
    
        guard let property = keyValueStore[storeKey] as? ValueTree.Property,
              let references = property.asValueTreeReferences() else {
            return []
        }
        
        return references.map { fetchValue(identifiedBy: $0.uniqueIdentifier)! }
    }
    
    public func store<T:StorablePrimitive>(_ value:T, for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let storeKey = self.storeKey(forCurrentValueKey: key)
        keyValueStore[storeKey] = value.storableValue
    }
    
    public func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let storeKey = self.storeKey(forCurrentValueKey: key)
        keyValueStore[storeKey] = value?.storableValue
    }
    
    public func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let storeKey = self.storeKey(forCurrentValueKey: key)
        keyValueStore[storeKey] = values.map { $0.storableValue }
    }
    
    public func store<T:Storable>(_ value: inout T, for key:String) {
        // Add a tuple with info for the parent entry to be able to find the child
        let storeKey = self.storeKey(forCurrentValueKey: key)
        keyValueStore[storeKey] = (identifier: value.metadata.uniqueIdentifier, type: T.storageType)
        
        // Recurse to store the value's data
        transaction {
            currentTreeReference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
            storeValueAndDescendents(of: &value)
        }
    }
    
    public func store<T:Storable>(_ value: inout T?, for key:String) {
        if var unwrappedValue = value {
            store(&unwrappedValue, for: key)
            value = unwrappedValue
        }
        else {
            // TODO: Handle removal from the store. Would have to use info from parent to locate
        }
    }
    
    public func store<T:Storable>(_ values: inout [T], for key:String) {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        let identifiers = values.map { $0.metadata.uniqueIdentifier }
        keyValueStore[storeKey] = (identifiers: identifiers, type: T.storageType)
        
        // Recurse to store the values data
        for var value in values {
            transaction {
                currentTreeReference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
                storeValueAndDescendents(of: &value)
            }
        }
    }
    
    /// Resolves conflicts and saves, and sets the value on out to resolved value.
    public func save<T:Storable>(_ value: inout T) {
        identifiersOfUnchanged = Set<UniqueIdentifier>()
        currentTreeReference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
        storeValueAndDescendents(of: &value)
    }
    
    func storeValueAndDescendents<T:Storable>(of value: inout T) {
        let storeValue:T? = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        
        var resolvedValue:T
        var resolvedVersion:StorageVersion = 0
        let resolvedTimestamp = Date.timeIntervalSinceReferenceDate
        var changed = true
        
        if storeValue == nil {
            // First save
            resolvedValue = value
            resolvedVersion = 0
        }
        else if storeValue!.isStorageEquivalent(to: value) && value.metadata == storeValue!.metadata {
            // Values unchanged from store. Don't save data again
            resolvedValue = value
            resolvedVersion = value.metadata.version
            changed = false
        }
        else if value.metadata.version == storeValue!.metadata.version {
            // Store has not changed since the base value was taken, so just save the new value directly
            resolvedValue = value
            resolvedVersion = value.metadata.version + 1
        }
        else {
            // Conflict with store. Resolve.
            resolvedValue = value.resolvedValue(forConflictWith: storeValue!)
            resolvedVersion = max(value.metadata.version, storeValue!.metadata.version) + 1
        }
        
        if changed {
            // Store metadata if changed
            resolvedValue.metadata.timestamp = resolvedTimestamp
            resolvedValue.metadata.version = resolvedVersion
            transaction {
                currentTreeReference = ValueTreeReference(uniqueIdentifier: currentTreeReference.uniqueIdentifier, storageType: T.storageType + metadataTypeSuffix)
                resolvedValue.metadata.store(in: self)
            }
        }
        else {
            // Store id of this unchanged value, so we can skip it in 'store' callbacks
            identifiersOfUnchanged.insert(value.metadata.uniqueIdentifier)
        }
        
        // Always call store, even if unchanged, to check for changed descendents
        resolvedValue.store(in: self)
        value = resolvedValue
    }
    
    public func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T? {
        var result: T?
        transaction {
            currentTreeReference = ValueTreeReference(uniqueIdentifier: uniqueIdentifier, storageType: T.storageType + metadataTypeSuffix)
            if let metadata = Metadata(withStorage: self) {
                currentTreeReference = ValueTreeReference(uniqueIdentifier: uniqueIdentifier, storageType: T.storageType)
                result = T.init(withStorage: self)
                result?.metadata = metadata
            }
        }
        return result
    }
    
    func transaction(in block: (Void)->Void ) {
        let storedReference = currentTreeReference
        block()
        currentTreeReference = storedReference
    }

    public func fetchValueTrees(forChangesSince cursor: Cursor?, completionHandler completion: (Error?, [ValueTree], Cursor)->Void) {
        // Gather identifiers by comparing the timestamps in metadata entries with cursor
        var identifiersToInclude = Set<UniqueIdentifier>()
        for (key, value) in keyValueStore {
            let parts = key.components(separatedBy: "/")
            let (type, id, propertyKey) = (parts[0], parts[1], parts[2])
            if type.hasSuffix(metadataTypeSuffix) && propertyKey == Metadata.Key.timestamp.rawValue {
                let time = value as! TimeInterval
                let timestampCursor = cursor as! TimestampCursor?
                if timestampCursor == nil || timestampCursor!.timestamp <= time {
                    identifiersToInclude.insert(id)
                }
            }
        }
        
        // TODO: Use a ValueTreeBuilder to build each ValueTree.
    }
    
    public func assimilate(_ ValueTrees: [ValueTree], completionHandler completion: CompletionHandler?) {
        // TODO: Implement inserting of changes
    }
}

