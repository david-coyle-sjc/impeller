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
    
    public enum Property: Equatable {
        case primitive(AnyStorablePrimitive)
        case optionalPrimitive(AnyStorablePrimitive?)
        case primitives([AnyStorablePrimitive])
        case valueTree(ValueTree)
        case optionalValueTree(ValueTree?)
        case valueTrees([ValueTree])
        case valueTreeReference(ValueTreeReference)
        case optionalValueTreeReference(ValueTreeReference?)
        case valueTreeReferences([ValueTreeReference])
        
        public var type: Int16 {
            switch self {
            case .primitive:
                return 10
            case .optionalPrimitive:
                return 20
            case .primitives:
                return 30
            case .valueTree:
                return 40
            case .optionalValueTree:
                return 50
            case .valueTrees:
                return 60
            case .valueTreeReference:
                return 70
            case .optionalValueTreeReference:
                return 80
            case .valueTreeReferences:
                return 90
            }
        }
        
        public var isOptionalType: Bool {
            switch self {
            case .primitive:
                return false
            case .optionalPrimitive:
                return true
            case .primitives:
                return false
            case .valueTree:
                return false
            case .optionalValueTree:
                return true
            case .valueTrees:
                return false
            case .valueTreeReference:
                return false
            case .optionalValueTreeReference:
                return true
            case .valueTreeReferences:
                return false
            }
        }
        
        public func asPrimitive() -> AnyStorablePrimitive? {
            switch self {
            case .primitive(let v):
                return v
            default:
                return nil
            }
        }
        
        public func asOptionalPrimitive() -> AnyStorablePrimitive?? {
            switch self {
            case .optionalPrimitive(let v):
                return v
            default:
                return nil
            }
        }
        
        public func asPrimitives() -> [AnyStorablePrimitive]? {
            switch self {
            case .primitives(let v):
                return v
            default:
                return nil
            }
        }
        
        public func asValueTree() -> ValueTree? {
            switch self {
            case .valueTree(let v):
                return v
            default:
                return nil
            }
        }
        
        public func asOptionalValueTree() -> ValueTree?? {
            switch self {
            case .optionalValueTree(let v):
                return v
            default:
                return nil
            }
        }
        
        public func asValueTrees() -> [ValueTree]? {
            switch self {
            case .valueTrees(let v):
                return v
            default:
                return nil
            }
        }
        
        public func asValueTreeReference() -> ValueTreeReference? {
            switch self {
            case .valueTreeReference(let v):
                return v
            case .valueTree(let v):
                return v.valueTreeReference
            default:
                return nil
            }
        }
        
        public func asOptionalValueTreeReference() -> ValueTreeReference?? {
            switch self {
            case .optionalValueTreeReference(let v):
                return v
            case .optionalValueTree(let v):
                return v?.valueTreeReference
            default:
                return nil
            }
        }
        
        public func asValueTreeReferences() -> [ValueTreeReference]? {
            switch self {
            case .valueTreeReferences(let v):
                return v
            case .valueTrees(let v):
                return v.map { $0.valueTreeReference }
            default:
                return nil
            }
        }
        
        public func referenceTransformed() -> Property {
            switch self {
            case .valueTree(let tree):
                return .valueTreeReference(tree.valueTreeReference)
            case .optionalValueTree(let tree):
                return .optionalValueTreeReference(tree?.valueTreeReference)
            case .valueTrees(let trees):
                return .valueTreeReferences(trees.map { $0.valueTreeReference })
            case .primitive, .optionalPrimitive, .primitives, .valueTreeReference, .optionalValueTreeReference, .valueTreeReferences:
                return self
            }
        }
        
        public static func ==(left: Property, right: Property) -> Bool {
            switch (left, right) {
            case let (.primitive(l), .primitive(r)):
                return l == r
            case let (.optionalPrimitive(l), .optionalPrimitive(r)):
                return l == r
            case let (.primitives(l), .primitives(r)):
                return l == r
            case let (.valueTree(l), .valueTree(r)):
                return l == r
            case let (.optionalValueTree(l), .optionalValueTree(r)):
                return l == r
            case let (.valueTrees(l), .valueTrees(r)):
                return l == r
            case let (.valueTreeReference(l), .valueTreeReference(r)):
                return l == r
            case let (.optionalValueTreeReference(l), .optionalValueTreeReference(r)):
                return l == r
            case let (.valueTreeReferences(l), .valueTreeReferences(r)):
                return l == r
            default:
                return false
            }
        }
    }
}

