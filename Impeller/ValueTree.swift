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
    
    private var propertiesByName = [String:Property]()
    
    public var valueTreeReference: ValueTreeReference {
        return ValueTreeReference(uniqueIdentifier: metadata.uniqueIdentifier, storageType: storageType)
    }
    
    public var propertyNames: [String] {
        return Array(propertiesByName.keys)
    }

    public init(storageType: StorageType, metadata: Metadata) {
        self.storageType = storageType
        self.metadata = metadata
    }
    
    public init(deepCopying other:ValueTree) {
        metadata = other.metadata
        storageType = other.storageType
        propertiesByName = other.propertiesByName
    }
    
    public func get(_ propertyName: String) -> Property? {
        return propertiesByName[propertyName]
    }
    
    public func set(_ propertyName: String, to property: Property) {
        propertiesByName[propertyName] = property
    }
    
    public var hashValue: Int {
        return metadata.uniqueIdentifier.hash
    }
    
    public static func ==(left: ValueTree, right: ValueTree) -> Bool {
        return left.propertiesByName == right.propertiesByName && left.metadata == right.metadata && left.storageType == right.storageType
    }
    
}

