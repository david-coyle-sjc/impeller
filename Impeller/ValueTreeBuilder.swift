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
        valueTree = ValueTree(T.storageType, identifiedBy: storable.metadata.uniqueIdentifier)
        var s = storable
        s.store(in: self)
    }
    
    func store<T:StorablePrimitive>(_ value:T, for key:String) {
        valueTree[key] = AnyStorablePrimitive(value)
    }
    
    func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        valueTree[key] = value != nil ? AnyStorablePrimitive(value!) : nil
    }
    
    func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        valueTree[key] = AnyStorablePrimitive(values)
    }
    
    func store<T:Storable>(_ value:inout T, for key:String) {
        valueTree[key] = AnyStorablePrimitive(value.metadata.uniqueIdentifier)
    }
    
    func store<T:Storable>(_ value:inout T?, for key:String) {
        if let id = value?.metadata.uniqueIdentifier {
            valueTree[key] = AnyStorablePrimitive(id)
        }
        else {
            valueTree[key] = nil
        }
    }
    
    func store<T:Storable>(_ values:inout [T], for key:String) {
        valueTree[key] = AnyStorablePrimitive(values.map { $0.metadata.uniqueIdentifier })
    }
}

