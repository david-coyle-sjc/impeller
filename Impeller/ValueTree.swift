//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 16/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public struct ValueTreeReference: Equatable {
    let uniqueIdentifier: UniqueIdentifier?
    let storageType: StorageType
    
    public static func ==(left: ValueTreeReference, right: ValueTreeReference) -> Bool {
        return left.uniqueIdentifier == right.uniqueIdentifier && left.storageType == right.storageType
    }
}

public class ValueTree: Equatable {
    var metadata: Metadata
    var storageType: StorageType
    
    public enum Property: Equatable {
        case primitive(AnyStorablePrimitive)
        case valueTree(ValueTree)
        case valueTrees([ValueTree])
        case valueTreeReference(ValueTreeReference)
        case valueTreeReferences([ValueTreeReference])
        
        public func referenceTranformed() -> Property {
            switch self {
            case .valueTree(let tree):
                return .valueTreeReference(tree.valueTreeReference)
            case .valueTrees(let trees):
                return .valueTreeReferences(trees.map { $0.valueTreeReference })
            case .primitive, .valueTreeReference, .valueTreeReferences:
                return self
            }
        }
        
        public static func ==(left: Property, right: Property) -> Bool {
            switch (left, right) {
            case let (.primitive(l), .primitive(r)):
                return l == r
            case let (.valueTree(l), .valueTree(r)):
                return l == r
            case let (.valueTrees(l), .valueTrees(r)):
                return l == r
            case let (.valueTreeReference(l), .valueTreeReference(r)):
                return l == r
            case let (.valueTreeReferences(l), .valueTreeReferences(r)):
                return l == r
            default:
                return false
            }
        }
    }
    
    private var propertiesByKey = [String:Property]()
    
    var valueTreeReference: ValueTreeReference {
        return ValueTreeReference(uniqueIdentifier: metadata.uniqueIdentifier, storageType: storageType)
    }

    init(storageType: StorageType, metadata: Metadata) {
        self.storageType = storageType
        self.metadata = metadata
    }
    
    func property(forKey key: String) -> Property? {
        return propertiesByKey[key]
    }
    
    func setProperty(_ property: Property, forKey key: String) {
        propertiesByKey[key] = property
    }
    
    public static func ==(left: ValueTree, right: ValueTree) -> Bool {
        let l = left.propertiesByKey.mapValues { $0.referenceTranformed() }
        let r = right.propertiesByKey.mapValues { $0.referenceTranformed() }
        return l == r && left.metadata == right.metadata && left.storageType == right.storageType
    }
}

