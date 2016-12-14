//
//  MemoryStorage
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public class MemoryStorage: Storage {
    
    private var storageDictionary = [String:Any]()
    private var currentStorageType = ""
    private var currentUniqueIdentifier = ""
    
    private class func storeKey(forStoreType type:String, identifier: UniqueIdentifier, key: String) -> String {
        return "\(type)_\(identifier)_\(key)"
    }
    
    private func storeKey(forCurrentValueKey key:String) -> String {
        return MemoryStorage.storeKey(forStoreType: currentStorageType, identifier: currentUniqueIdentifier, key: key)
    }
    
    public func value<T:StorablePrimitive>(for key:String) -> T? {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        if let value = storageDictionary[storeKey] {
            return T(withStorableValue: value)
        }
        else {
            return nil
        }
    }
    
    public func values<T:StorablePrimitive>(for key:String) -> [T] {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        return storageDictionary[storeKey] as? [T] ?? []
    }
    
    public func value<T:Storable>(for key:String) -> T? {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        
        guard let info = storageDictionary[storeKey] as? [String:Any] else {
            return nil
        }
        guard let identifier = info["id"] as? UniqueIdentifier else {
            return nil
        }
        
        return fetchValue(identifiedBy: identifier)
    }
    
    public func values<T:Storable>(for key:String) -> [T] {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        
        guard let info = storageDictionary[storeKey] as? [String:Any] else {
            return []
        }
        guard let identifiers = info["ids"] as? [UniqueIdentifier] else {
            return []
        }
        
        return identifiers.flatMap { fetchValue(identifiedBy: $0) }
    }
    
    public func store<T:StorablePrimitive>(_ value:T, for key:String) {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        storageDictionary[storeKey] = value.storableValue
    }
    
    public func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        storageDictionary[storeKey] = value?.storableValue
    }
    
    public func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        let storeKey = self.storeKey(forCurrentValueKey: key)
        storageDictionary[storeKey] = values.map { $0.storableValue }
    }
    
    public func store<T:Storable>(_ value: inout T, for key:String) {
        // Add a dictionary with info for the parent entry to be able to find the child
        let storeKey = self.storeKey(forCurrentValueKey: key)
        storageDictionary[storeKey] = ["id":value.metadata.uniqueIdentifier, "type":T.storageType]
        
        // Recurse to store the value's data
        transaction {
            currentUniqueIdentifier = value.metadata.uniqueIdentifier
            currentStorageType = T.storageType
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
        storageDictionary[storeKey] = ["ids":identifiers, "type":T.storageType]
        
        // Recurse to store the values data
        for var value in values {
            transaction {
                currentUniqueIdentifier = value.metadata.uniqueIdentifier
                currentStorageType = T.storageType
                storeValueAndDescendents(of: &value)
            }
        }
    }
    
    /// Resolves conflicts and saves, and sets the value on out to resolved value.
    public func save<T:Storable>(_ value: inout T) {
        currentUniqueIdentifier = value.metadata.uniqueIdentifier
        currentStorageType = T.storageType
        storeValueAndDescendents(of: &value)
    }
    
    func storeValueAndDescendents<T:Storable>(of value: inout T) {
        let storeValue:T? = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        
        var resolvedValue:T
        var resolvedVersion:StorageVersion = 0
        let resolvedTimestamp = Date.timeIntervalSinceReferenceDate
        var saveResult = true
        
        if storeValue == nil {
            // First save
            resolvedValue = value
            resolvedVersion = 0
        }
        else if storeValue!.isStorageEquivalent(to: value) && value.metadata == storeValue!.metadata {
            // Values unchanged from store. Don't save data again
            resolvedValue = storeValue!
            resolvedVersion = storeValue!.metadata.version
            saveResult = false
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
        
        if saveResult {
            // Store result
            resolvedValue.store(in: self)
            
            // Store metadata
            resolvedValue.metadata.timestamp = resolvedTimestamp
            resolvedValue.metadata.version = resolvedVersion
            transaction {
                currentStorageType = T.storageType + "Metadata"
                resolvedValue.metadata.store(in: self)
            }
        }
        
        value = resolvedValue
    }
    
    public func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T? {
        var result: T?
        transaction {
            currentUniqueIdentifier = uniqueIdentifier
            currentStorageType = T.storageType + "Metadata"
            if let metadata = Metadata(withStorage: self) {
                currentStorageType = T.storageType
                result = T(withStorage: self)
                result?.metadata = metadata
            }
        }
        return result
    }
    
    func transaction(in block: (Void)->Void ) {
        let storedIdentifier = currentUniqueIdentifier
        let storedType = currentStorageType
        
        block()
        
        currentUniqueIdentifier = storedIdentifier
        currentStorageType = storedType
    }

}
