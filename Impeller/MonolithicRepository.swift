//
//  MonolithicRepository
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


public protocol Serializer {
    func load(from url:URL) throws -> [String:ValueTree]
    func save(_ valueTreesByKey:[String:ValueTree], to url:URL) throws
}


/// All data is in memory. This class does not persist data to disk,
/// but other classes can be used to do that.
public class MonolithicRepository: LocalRepository, Exchangable {
    public var uniqueIdentifier: UniqueIdentifier = uuid()
    private var valueTreesByKey = [String:ValueTree]()
    private var currentTreeReference = ValueTreeReference(uniqueIdentifier: "", storedType: "")
    private var identifiersOfUnchanged = Set<UniqueIdentifier>()
    private var commitContext: Any?
    private var commitTimestamp = Date.distantPast.timeIntervalSinceReferenceDate
    private var isDeletionPass = false

    public init() {}
    
    private class func key(for reference: ValueTreeReference) -> String {
        return "\(reference.storedType)/\(reference.uniqueIdentifier)"
    }
    
    private var currentValueTreeKey: String {
        return MonolithicRepository.key(for: currentTreeReference)
    }
    
    private var currentValueTree: ValueTree? {
        return valueTreesByKey[currentValueTreeKey]
    }
    
    private func currentTreeProperty(_ key: String) -> Property? {
        return valueTreesByKey[currentValueTreeKey]?.get(key)
    }
    
    public func read<T:StorablePrimitive>(_ key:String) -> T? {
        if  let property = currentTreeProperty(key),
            let primitive = property.asPrimitive() {
            return T(primitive)
        }
        else {
            return nil
        }
    }
    
    public func read<T:StorablePrimitive>(optionalFor key:String) -> T?? {
        if  let property = currentTreeProperty(key),
            let optionalPrimitive = property.asOptionalPrimitive() {
            if let primitive = optionalPrimitive {
                return T(primitive)
            }
            else {
                return nil as T?
            }
        }
        else {
            return nil
        }
    }
    
    public func read<T:StorablePrimitive>(_ key:String) -> [T]? {
        if  let property = currentTreeProperty(key),
            let primitives = property.asPrimitives() {
            return primitives.flatMap { T($0) }
        }
        else {
            return nil
        }
    }
    
    public func read<T:Storable>(_ key:String) -> T? {
        if  let property = currentTreeProperty(key),
            let reference = property.asValueTreeReference() {
            return fetchValue(identifiedBy: reference.uniqueIdentifier)
        }
        else {
            return nil
        }
    }
    
    public func read<T:Storable>(optionalFor key:String) -> T?? {
        if  let property = currentTreeProperty(key),
            let optionalReference = property.asOptionalValueTreeReference(),
            let reference = optionalReference {
            return fetchValue(identifiedBy: reference.uniqueIdentifier)
        }
        else {
            return nil
        }
    }
    
    public func read<T:Storable>(_ key:String) -> [T]? {
        if  let property = currentTreeProperty(key),
            let references = property.asValueTreeReferences() {
            return references.map { fetchValue(identifiedBy: $0.uniqueIdentifier)! }
        }
        else {
            return nil
        }
    }
    
    public func write<T:StorablePrimitive>(_ value:T, for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let primitive = Primitive(value: value)
        let property: Property = .primitive(primitive!)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
    }
    
    public func write<T:StorablePrimitive>(_ value:T?, for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let primitive = value != nil ? Primitive(value: value!) : nil
        let property: Property = .optionalPrimitive(primitive)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
    }
    
    public func write<T:StorablePrimitive>(_ values:[T], for key:String) {
        guard !identifiersOfUnchanged.contains(currentTreeReference.uniqueIdentifier) else { return }
        let primitives = values.map { Primitive(value: $0)! }
        let property: Property = .primitives(primitives)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
    }
    
    public func write<T:Storable>(_ value: inout T, for key:String) {
        let reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storedType: T.storedType)
        
        // Fetch existing store value of descendant, and delete (if it differs from new reference)
        if let oldReference = valueTreesByKey[currentValueTreeKey]!.get(key)?.asValueTreeReference(), reference != oldReference {
            var oldValue: T = fetchValue(identifiedBy: oldReference.uniqueIdentifier)!
            transaction {
                isDeletionPass = true
                currentTreeReference = oldReference
                writeValueAndDescendants(of: &oldValue)
            }
        }

        // Store new property
        let property: Property = .valueTreeReference(reference)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)

        // Recurse to store the new value's data
        transaction {
            currentTreeReference = reference
            writeValueAndDescendants(of: &value)
        }
    }
    
    public func write<T:Storable>(_ value: inout T?, for key:String) {
        var reference: ValueTreeReference?
        if let value = value {
            reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storedType: T.storedType)
        }
        
        // Fetch existing store value of descendant, and delete
        if  let oldOptionalReference = valueTreesByKey[currentValueTreeKey]!.get(key)?.asOptionalValueTreeReference(),
            let oldReference = oldOptionalReference,
            oldOptionalReference != reference {
            var oldValue: T = fetchValue(identifiedBy: oldReference.uniqueIdentifier)!
            transaction {
                isDeletionPass = true
                currentTreeReference = oldReference
                writeValueAndDescendants(of: &oldValue)
            }
        }
        
        // Store new property
        let property: Property = .optionalValueTreeReference(reference)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
        
        // Recurse to store the value's data
        guard value != nil else { return }
        transaction {
            currentTreeReference = reference!
            var updatedValue = value!
            writeValueAndDescendants(of: &updatedValue)
            value = updatedValue
        }
    }
    
    public func write<T:Storable>(_ values: inout [T], for key:String) {
        let references = values.map {
            ValueTreeReference(uniqueIdentifier: $0.metadata.uniqueIdentifier, storedType: T.storedType)
        }
        
        // Determine which values get orphaned, and delete them
        if let oldReferences = valueTreesByKey[currentValueTreeKey]!.get(key)?.asValueTreeReferences() {
            let orphanedReferences = Set(oldReferences).subtracting(Set(references))
            for orphanedReference in orphanedReferences {
                var orphanedValue: T = fetchValue(identifiedBy: orphanedReference.uniqueIdentifier)!
                transaction {
                    isDeletionPass = true
                    currentTreeReference = orphanedReference
                    writeValueAndDescendants(of: &orphanedValue)
                }
            }
        }
        
        // Store new property
        let property: Property = .valueTreeReferences(references)
        valueTreesByKey[currentValueTreeKey]!.set(key, to: property)
        
        // Recurse to store the value's data
        var updatedValues = [T]()
        for (var value, reference) in zip(values, references) {
            transaction {
                currentTreeReference = reference
                writeValueAndDescendants(of: &value)
                updatedValues.append(value)
            }
        }
        values = updatedValues
    }
    
    private func prepareToMakeChanges<T:Storable>(forRoot value: T) {
        commitTimestamp = Date.timeIntervalSinceReferenceDate
        identifiersOfUnchanged = Set<UniqueIdentifier>()
        currentTreeReference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storedType: T.storedType)
        isDeletionPass = false
        commitContext = nil
    }
    
    /// Resolves conflicts and commits, and sets the value on out to resolved value.
    public func commit<T:Storable>(_ value: inout T, context: Any? = nil) {
        prepareToMakeChanges(forRoot: value)
        commitContext = context
        writeValueAndDescendants(of: &value)
    }
    
    public func delete<T:Storable>(_ value: inout T) {
        prepareToMakeChanges(forRoot: value)
        isDeletionPass = true
        writeValueAndDescendants(of: &value)
    }
    
    private func writeValueAndDescendants<T:Storable>(of value: inout T) {
        let storeValue:T? = fetchValue(identifiedBy: value.metadata.uniqueIdentifier)
        if storeValue == nil {
            valueTreesByKey[currentValueTreeKey] = ValueTree(storedType: T.storedType, metadata: value.metadata)
        }
        
        var resolvedValue:T
        var resolvedVersion:StoredVersion = 0
        let resolvedTimestamp = commitTimestamp
        var changed = true
        
        if storeValue == nil {
            // First commit
            resolvedValue = value
            resolvedVersion = 0
        }
        else if storeValue!.isRepositoryEquivalent(to: value) && value.metadata == storeValue!.metadata {
            // Values unchanged from store. Don't commit data again
            resolvedValue = value
            resolvedVersion = value.metadata.version
            changed = false
        }
        else if value.metadata.version == storeValue!.metadata.version {
            // Store has not changed since the base value was taken, so just commit the new value directly
            resolvedValue = value
            resolvedVersion = value.metadata.version + 1
        }
        else {
            // Conflict with store. Resolve.
            resolvedValue = value.resolvedValue(forConflictWith: storeValue!, context: commitContext)
            resolvedVersion = max(value.metadata.version, storeValue!.metadata.version) + 1
        }
        
        if isDeletionPass && !resolvedValue.metadata.isDeleted {
            resolvedValue.metadata.isDeleted = true
            resolvedVersion += 1
            changed = true
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
        
        // Always call write, even if unchanged, to check for changed descendants
        resolvedValue.write(in: self)
        value = resolvedValue
    }
    
    public func fetchValue<T:Storable>(identifiedBy uniqueIdentifier:UniqueIdentifier) -> T? {
        var result: T?
        transaction {
            currentTreeReference = ValueTreeReference(uniqueIdentifier: uniqueIdentifier, storedType: T.storedType)
            guard let valueTree = currentValueTree, !valueTree.metadata.isDeleted else {
                return
            }
            
            result = T.init(readingFrom: self)
            result?.metadata = valueTree.metadata
        }
        return result
    }
    
    private func transaction(in block: (Void)->Void ) {
        let storedReference = currentTreeReference
        let isDeletion = isDeletionPass
        block()
        isDeletionPass = isDeletion
        currentTreeReference = storedReference
    }

    public func push(changesSince cursor: Cursor?, completionHandler completion: @escaping (Error?, [ValueTree], Cursor?)->Void) {
        let timestampCursor = cursor as? TimestampCursor
        var maximumTimestamp = timestampCursor?.timestamp ?? Date.distantPast.timeIntervalSinceReferenceDate
        var valueTrees = [ValueTree]()
        for (_, valueTree) in valueTreesByKey {
            let time = valueTree.metadata.timestamp
            if timestampCursor == nil || timestampCursor!.timestamp <= time {
                valueTrees.append(valueTree)
                maximumTimestamp = max(maximumTimestamp, time)
            }
        }
        DispatchQueue.main.async {
            completion(nil, valueTrees, TimestampCursor(timestamp: maximumTimestamp))
        }
    }
    
    public func pull(_ valueTrees: [ValueTree], completionHandler completion: @escaping CompletionHandler) {
        for newTree in valueTrees {
            let reference = ValueTreeReference(uniqueIdentifier: newTree.metadata.uniqueIdentifier, storedType: newTree.storedType)
            let key = MonolithicRepository.key(for: reference)
            valueTreesByKey[key] = newTree.merged(with: valueTreesByKey[key])
        }
        DispatchQueue.main.async {
            completion(nil)
        }
    }
    
    public func load(from url:URL, with serializer: Serializer) throws {
        try valueTreesByKey = serializer.load(from:url)
    }
    
    public func save(to url:URL, with serializer: Serializer) throws {
        try serializer.save(valueTreesByKey, to:url)
    }
}

