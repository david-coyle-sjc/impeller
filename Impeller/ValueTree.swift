//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 16/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public struct ValueTreeReference: Equatable {
    let uniqueIdentifier: UniqueIdentifier
    let storageType: StorageType
    
    public static func ==(left: ValueTreeReference, right: ValueTreeReference) -> Bool {
        return left.uniqueIdentifier == right.uniqueIdentifier && left.storageType == right.storageType
    }
}


public final class ValueTree: Equatable, Hashable {
    public var metadata: Metadata
    public var storageType: StorageType
    
    private var propertiesByKey = [String:Property]()
    
    public var valueTreeReference: ValueTreeReference {
        return ValueTreeReference(uniqueIdentifier: metadata.uniqueIdentifier, storageType: storageType)
    }

    public init(storageType: StorageType, metadata: Metadata) {
        self.storageType = storageType
        self.metadata = metadata
    }
    
    public init(deepCopying other:ValueTree) {
        metadata = other.metadata
        storageType = other.storageType
        propertiesByKey = other.propertiesByKey
    }
    
    public func get(_ key: String) -> Property? {
        return propertiesByKey[key]
    }
    
    public func set(_ key: String, to property: Property) {
        propertiesByKey[key] = property
    }
    
    public var hashValue: Int {
        return metadata.uniqueIdentifier.hash
    }
    
    public static func ==(left: ValueTree, right: ValueTree) -> Bool {
        return left.propertiesByKey == right.propertiesByKey && left.metadata == right.metadata && left.storageType == right.storageType
    }
    
}

