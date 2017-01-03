//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 16/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public struct ValueTreeReference: Equatable {
    let uniqueIdentifier: UniqueIdentifier
    let storedType: StoredType
    
    public static func ==(left: ValueTreeReference, right: ValueTreeReference) -> Bool {
        return left.uniqueIdentifier == right.uniqueIdentifier && left.storedType == right.storedType
    }
}


public final class ValueTree: Equatable, Hashable {
    public var metadata: Metadata
    public var storedType: StoredType
    
    private var propertiesByName = [String:Property]()
    
    public var valueTreeReference: ValueTreeReference {
        return ValueTreeReference(uniqueIdentifier: metadata.uniqueIdentifier, storedType: storedType)
    }
    
    public var propertyNames: [String] {
        return Array(propertiesByName.keys)
    }

    public init(storedType: StoredType, metadata: Metadata) {
        self.storedType = storedType
        self.metadata = metadata
    }
    
    public init(deepCopying other:ValueTree) {
        metadata = other.metadata
        storedType = other.storedType
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
        return left.propertiesByName == right.propertiesByName && left.metadata == right.metadata && left.storedType == right.storedType
    }
    
}

