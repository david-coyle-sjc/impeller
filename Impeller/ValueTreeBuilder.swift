//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 15/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

final class ValueTreeBuilder<T:Storable> : StorageSink {
    private (set) var valueTree: ValueTree
    private var storable: T
    
    init(_ storable:T) {
        valueTree = ValueTree(storageType: T.storageType, metadata: storable.metadata)
        self.storable = storable
        self.save(&self.storable)
    }
    
    func save<T:Storable>(_ value: inout T, context: Any? = nil) {
        storable.store(in: self)
    }
    
    func store<T:StorablePrimitive>(_ value:T, for key:String) {
        let storable = AnyStorablePrimitive(value)
        valueTree.set(key, to: .primitive(storable))
    }
    
    func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        let storable = value != nil ? AnyStorablePrimitive(value!) : nil
        valueTree.set(key, to: .optionalPrimitive(storable))
    }
    
    func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        let storables = values.map { AnyStorablePrimitive($0) }
        valueTree.set(key, to: .primitives(storables))
    }
    
    func store<T:Storable>(_ value:inout T, for key:String) {
        let reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storageType: T.storageType)
        valueTree.set(key, to: .valueTreeReference(reference))
    }
    
    func store<T:Storable>(_ value:inout T?, for key:String) {
        let id = value?.metadata.uniqueIdentifier
        let reference = id != nil ? ValueTreeReference(uniqueIdentifier: id!, storageType: T.storageType) : nil
        valueTree.set(key, to: .optionalValueTreeReference(reference))
    }
    
    func store<T:Storable>(_ values:inout [T], for key:String) {
        let references = values.map {
            ValueTreeReference(uniqueIdentifier: $0.metadata.uniqueIdentifier, storageType: T.storageType)
        }
        valueTree.set(key, to: .valueTreeReferences(references))
    }
}

