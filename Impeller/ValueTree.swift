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


public class ValueTree: Equatable {
    var metadata: Metadata
    var storageType: StorageType
    
    public enum Property: Equatable {
        case primitive(AnyStorablePrimitive)
        case optionalPrimitive(AnyStorablePrimitive?)
        case primitiveArray([AnyStorablePrimitive])
        case valueTree(ValueTree)
        case optionalValueTree(ValueTree?)
        case valueTrees([ValueTree])
        case valueTreeReference(ValueTreeReference)
        case optionalValueTreeReference(ValueTreeReference?)
        case valueTreeReferences([ValueTreeReference])
        
        func asPrimitive() -> AnyStorablePrimitive? {
            switch self {
            case .primitive(let v):
                return v
            default:
                return nil
            }
        }
        
        func asOptionalPrimitive() -> AnyStorablePrimitive?? {
            switch self {
            case .optionalPrimitive(let v):
                return v
            default:
                return nil
            }
        }
        
        func asPrimitiveArray() -> [AnyStorablePrimitive]? {
            switch self {
            case .primitiveArray(let v):
                return v
            default:
                return nil
            }
        }
        
        func asValueTree() -> ValueTree? {
            switch self {
            case .valueTree(let v):
                return v
            default:
                return nil
            }
        }
        
        func asOptionalValueTree() -> ValueTree?? {
            switch self {
            case .optionalValueTree(let v):
                return v
            default:
                return nil
            }
        }
        
        func asValueTrees() -> [ValueTree]? {
            switch self {
            case .valueTrees(let v):
                return v
            default:
                return nil
            }
        }
        
        func asValueTreeReference() -> ValueTreeReference? {
            switch self {
            case .valueTreeReference(let v):
                return v
            case .valueTree(let v):
                return v.valueTreeReference
            default:
                return nil
            }
        }
        
        func asOptionalValueTreeReference() -> ValueTreeReference?? {
            switch self {
            case .optionalValueTreeReference(let v):
                return v
            case .optionalValueTree(let v):
                return v?.valueTreeReference
            default:
                return nil
            }
        }
        
        func asValueTreeReferences() -> [ValueTreeReference]? {
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
            case .primitive, .optionalPrimitive, .primitiveArray, .valueTreeReference, .optionalValueTreeReference, .valueTreeReferences:
                return self
            }
        }
        
        public static func ==(left: Property, right: Property) -> Bool {
            switch (left, right) {
            case let (.primitive(l), .primitive(r)):
                return l == r
            case let (.optionalPrimitive(l), .optionalPrimitive(r)):
                return l == r
            case let (.primitiveArray(l), .primitiveArray(r)):
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
    
    private var propertiesByKey = [String:Property]()
    
    var valueTreeReference: ValueTreeReference {
        return ValueTreeReference(uniqueIdentifier: metadata.uniqueIdentifier, storageType: storageType)
    }

    init(storageType: StorageType, metadata: Metadata) {
        self.storageType = storageType
        self.metadata = metadata
    }
    
    func get(_ key: String) -> Property? {
        return propertiesByKey[key]
    }
    
    func set(_ key: String, to property: Property) {
        propertiesByKey[key] = property
    }
    
    public static func ==(left: ValueTree, right: ValueTree) -> Bool {
        let l = left.propertiesByKey.mapValues { $0.referenceTransformed() }
        let r = right.propertiesByKey.mapValues { $0.referenceTransformed() }
        return l == r && left.metadata == right.metadata && left.storageType == right.storageType
    }
}

