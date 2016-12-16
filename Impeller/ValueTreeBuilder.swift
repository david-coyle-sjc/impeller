//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 15/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

final class ValueTreeBuilder: StorageSink {
    private (set) var valueTree: ValueTree
    
    init<T:Storable>(_ storable:T) {
        valueTree = ValueTree(storageType: T.storageType, metadata: storable.metadata)
        var s = storable
        s.store(in: self)
    }
    
    func store<T:StorablePrimitive>(_ value:T, for key:String) {
        let storable = AnyStorablePrimitive(value)
        valueTree.setStoragePrimitive(storable, forKey: key)
    }
    
    func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        let storable = value != nil ? AnyStorablePrimitive(value!) : AnyStorablePrimitive(Null())
        valueTree.setStoragePrimitive(storable, forKey: key)
    }
    
    func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        let storable = AnyStorablePrimitive(values)
        valueTree.setStoragePrimitive(storable, forKey: key)
    }
    
    func store<T:Storable>(_ value:inout T, for key:String) {
        let reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
        valueTree.setSubTreeReference(reference, forKey:key)
    }
    
    func store<T:Storable>(_ value:inout T?, for key:String) {
        let id = value?.metadata.uniqueIdentifier
        let reference = ValueTreeReference(uniqueIdentifier: id, storageType: T.storageType)
        valueTree.setSubTreeReference(reference, forKey:key)
    }
    
    func store<T:Storable>(_ values:inout [T], for key:String) {
        valueTree.set
        valueTree[key] = AnyStorablePrimitive(values.map { $0.metadata.uniqueIdentifier })
    }
}

