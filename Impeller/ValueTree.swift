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
        
        var newPropertiesByKey = [String:Property]()
        for (key, value) in other.propertiesByKey {
            switch value {
            case .valueTree(let tree):
                newPropertiesByKey[key] = .valueTree(ValueTree(deepCopying:tree))
            case .valueTrees(let trees):
                newPropertiesByKey[key] = .valueTrees(trees.map { ValueTree(deepCopying:$0) })
            case .optionalValueTree(let tree):
                newPropertiesByKey[key] = .optionalValueTree(tree == nil ? nil : ValueTree(deepCopying:tree!))
            default:
                newPropertiesByKey[key] = value
            }
        }
        propertiesByKey = newPropertiesByKey
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
        let l = left.propertiesByKey.mapValues { $0.referenceTransformed() }
        let r = right.propertiesByKey.mapValues { $0.referenceTransformed() }
        return l == r && left.metadata == right.metadata && left.storageType == right.storageType
    }
    
}

