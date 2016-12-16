//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 16/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public struct ValueTreeReference: Equatable {
    let uniqueIdentifier: UniqueIdentifier
    let type: StorageType
    
    public static func ==(left: ValueTreeReference, right: ValueTreeReference) -> Bool {
        return left.uniqueIdentifier == right.uniqueIdentifier && left.type == right.type
    }
}

public class ValueTree: Equatable {
    public var metadata: Metadata
    public var storableType: StorageType
    
    private var primitivesByKey = [String:AnyStorablePrimitive]()
    private var subTreeReferencesByKey = [String:ValueTreeReference]()
    private var subTreesByKey = [String:ValueTree]()
    
    public var valueTreeReference: ValueTreeReference {
        return ValueTreeReference(uniqueIdentifier: metadata.uniqueIdentifier, type: storableType)
    }
    
    private var allSubTreeReferences: [String:ValueTreeReference] {
        return subTreesByKey.reduce(subTreeReferencesByKey) { (result, pair) in
            let newValueTreeReference = subTreesByKey[pair.key]!.valueTreeReference
            return result.appending(newValueTreeReference, for: pair.key)
        }
    }

    init(storableType: StorageType, metadata: Metadata) {
        self.storableType = storableType
        self.metadata = metadata
    }
    
    func storablePrimitive(forKey key: String) -> AnyStorablePrimitive? {
        return primitivesByKey[key]
    }
    
    func setStorablePrimitive(_ primitive: AnyStorablePrimitive, forKey key: String) {
        primitivesByKey[key] = primitive
    }
    
    func subTree(forKey key: String) -> ValueTree? {
        return subTreesByKey[key]
    }
    
    func setSubTree(_ subTree: ValueTree, forKey key: String) {
        subTreesByKey[key] = subTree
    }
    
    func subTreeReference(forKey key: String) -> ValueTreeReference? {
        return subTreeReferencesByKey[key] ?? subTreesByKey[key]?.valueTreeReference
    }
    
    func setSubTreeReference(_ reference: ValueTreeReference, forKey key: String) {
        subTreeReferencesByKey[key] = reference
    }
    
    public static func ==(left: ValueTree, right: ValueTree) -> Bool {
        let primitivesAreEqual = left.primitivesByKey == right.primitivesByKey
        let subTreeValueTreeReferencesAreEqual = left.allSubTreeReferences == right.allSubTreeReferences
        return primitivesAreEqual && subTreeValueTreeReferencesAreEqual
    }
}

