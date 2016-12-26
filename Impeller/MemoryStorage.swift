//
//  MemoryStorage
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//


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
    private var valueTreesByKey = [String:ValueTree]()
    private var currentTreeReference = ValueTreeReference(uniqueIdentifier: "", storageType: "")
    private var identifiersOfUnchanged = Set<UniqueIdentifier>()
    
    private class func key(for reference: ValueTreeReference) -> String {
        return "\(reference.storageType)/\(reference.uniqueIdentifier)"
    }
    
    private var currentValueTreeKey: String {
        return MemoryStorage.key(for: currentTreeReference)
    }
    
    private var currentValueTree: ValueTree? {
        return valueTreesByKey[currentValueTreeKey]
    }
    
    private func currentTreeProperty(_ key: String) -> ValueTree.Property? {
        return valueTreesByKey[currentValueTreeKey]?.get(key)
    }
    
    public func value<T:StorablePrimitive>(for key:String) -> T? {
        if  let property = currentTreeProperty(key),
            let value = property.asPrimitive()?.storableValue {
            return T(withStorableValue: value)
        }
        else {
            return nil
        }
    }
    
    public func optionalValue<T:StorablePrimitive>(for key:String) -> T?? {
        if  let property = currentTreeProperty(key),
            let optionalValue = property.asOptionalPrimitive() {
            if let value = optionalValue?.storableValue {
                return T(withStorableValue: value)
            }
            else {
                return nil as T?
            }
        }
        else {
            return nil
        }
    }
    
    public func values<T:StorablePrimitive>(for key:String) -> [T]? {
        if  let property = currentTreeProperty(key),
            let array = property.asPrimitives() {
            return array.flatMap { T(withStorableValue: $0.storableValue) }
        }
        else {
            return nil
        }
    }
    
    public func value<T:Storable>(for key:String) -> T? {
        if  let property = currentTreeProperty(key),
            let reference = property.asValueTreeReference() {
            return fetchValue(identifiedBy: reference.uniqueIdentifier)
        }
        else {
            return nil
        }
    }
    
    public func optionalValue<T:Storable>(for key:String) -> T?? {
        if  let property = currentTreeProperty(key),
            let optionalReference = property.asOptionalValueTreeReference(),
            let reference = optionalReference {
            return fetchValue(identifiedBy: reference.uniqueIdentifier)
        }
        else {
            return nil
        }
    }
    
    public func values<T:Storable>(for key:String) -> [T]? {
        if  let property = currentTreeProperty(key),
            let references = property.asValueTreeReferences() {
            return references.map { fetchValue(identifiedBy: $0.uniqueIdentifier)! }
        }
        else {
            return nil
        }
    }
    
    public func store<T:StorablePrimitive>(_ value:T, for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let property: ValueTree.Property = .primitive(AnyStorablePrimitive(value))
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
    }
    
    public func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let optionalStorable = value != nil ? AnyStorablePrimitive(value!) : nil
        let property: ValueTree.Property = .optionalPrimitive(optionalStorable)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
    }
    
    public func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let storables = values.map { AnyStorablePrimitive($0) }
        let property: ValueTree.Property = .primitives(storables)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
    }
    
    public func store<T:Storable>(_ value: inout T, for key:String) {
        let reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
        let property: ValueTree.Property = .valueTreeReference(reference)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)

        // Recurse to store the value's data
        transaction {
            currentTreeReference = reference
            storeValueAndDescendents(of: &value)
        }
    }
    
    // TODO: If nil is passed here, effectively all subtrees are deleted. Need some logic to handle that.
    // Perhaps we need to wait until we have parent pointers to do this well.
    public func store<T:Storable>(_ value: inout T?, for key:String) {
        var reference: ValueTreeReference!
        if let value = value {
            reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
        }
        
        let property: ValueTree.Property = .optionalValueTreeReference(reference)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
        
        // Recurse to store the value's data
        guard value != nil else { return }
        transaction {
            currentTreeReference = reference
            var updatedValue = value!
            storeValueAndDescendents(of: &updatedValue)
            value = updatedValue
        }
    }
    
    public func store<T:Storable>(_ values: inout [T], for key:String) {
        let references = values.map {
            ValueTreeReference(uniqueIdentifier: $0.metadata.uniqueIdentifier, storageType: T.storageType)
        }
        
        let property: ValueTree.Property = .valueTreeReferences(references)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
        
        // Recurse to store the value's data
        var updatedValues = [T]()
        for (var value, reference) in zip(values, references) {
            transaction {
                currentTreeReference = reference
                storeValueAndDescendents(of: &value)
                updatedValues.append(value)
            }
        }
        values = updatedValues
    }
    
    /// Resolves conflicts and saves, and sets the value on out to resolved value.
    public func save<T:Storable>(_ value: inout T) {
        identifiersOfUnchanged = Set<UniqueIdentifier>()
        currentTreeReference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
        storeValueAndDescendents(of: &value)
    }
    
    func storeValueAndDescendents<T:Storable>(of value: inout T) {
        let storeValue:T? = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        if storeValue == nil {
            valueTreesByKey[currentValueTreeKey] = ValueTree(storageType: T.storageType, metadata: value.metadata)
        }
        
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
            currentValueTree!.metadata = resolvedValue.metadata
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
            currentTreeReference = ValueTreeReference(uniqueIdentifier: uniqueIdentifier, storageType: T.storageType)
            guard let valueTree = currentValueTree else {
                return
            }
            
            result = T.init(withStorage: self)
            result?.metadata = valueTree.metadata
        }
        return result
    }
    
    func transaction(in block: (Void)->Void ) {
        let storedReference = currentTreeReference
        block()
        currentTreeReference = storedReference
    }

    public func fetchValueTrees(forChangesSince cursor: Cursor?, completionHandler completion: (Error?, [ValueTree], Cursor)->Void) {
        let timestampCursor = cursor as! TimestampCursor?
        var maximumTimestamp = timestampCursor?.timestamp ?? Date.distantPast.timeIntervalSinceReferenceDate
        var valueTrees = [ValueTree]()
        for (_, valueTree) in valueTreesByKey {
            let time = valueTree.metadata.timestamp
            if timestampCursor == nil || timestampCursor!.timestamp <= time {
                valueTrees.append(valueTree)
                maximumTimestamp = max(maximumTimestamp, time)
            }
        }
        completion(nil, valueTrees, TimestampCursor(timestamp: maximumTimestamp))
    }
    
    public func assimilate(_ ValueTrees: [ValueTree], completionHandler completion: CompletionHandler?) {
        // TODO: Implement inserting of changes
    }
}

