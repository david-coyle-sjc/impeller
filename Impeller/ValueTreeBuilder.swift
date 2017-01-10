//
//  ValueTree.swift
//  Impeller
//
//  Created by Drew McCormack on 15/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

final class ValueTreeBuilder<T:Storable> : WriteRepository {
    private (set) var valueTree: ValueTree
    private var storable: T
    
    init(_ storable:T) {
        valueTree = ValueTree(storedType: T.storedType, metadata: storable.metadata)
        self.storable = storable
        self.commit(&self.storable)
    }
    
    func commit<T:Storable>(_ value: inout T, context: Any? = nil) {
        storable.write(in: self)
    }
    
    func write<T:StorablePrimitive>(_ value:T, for key:String) {
        let primitive = Primitive(value: value)
        valueTree.set(key, to: .primitive(primitive!))
    }
    
    func write<T:StorablePrimitive>(_ value:T?, for key:String) {
        let primitive = value != nil ? Primitive(value: value!) : nil
        valueTree.set(key, to: .optionalPrimitive(primitive))
    }
    
    func write<T:StorablePrimitive>(_ values:[T], for key:String) {
        let primitives = values.map { Primitive(value: $0)! }
        valueTree.set(key, to: .primitives(primitives))
    }
    
    func write<T:Storable>(_ value:inout T, for key:String) {
        let reference = ValueTreeReference(uniqueIdentifier: value.metadata.uniqueIdentifier, storedType: T.storedType)
        valueTree.set(key, to: .valueTreeReference(reference))
    }
    
    func write<T:Storable>(_ value:inout T?, for key:String) {
        let id = value?.metadata.uniqueIdentifier
        let reference = id != nil ? ValueTreeReference(uniqueIdentifier: id!, storedType: T.storedType) : nil
        valueTree.set(key, to: .optionalValueTreeReference(reference))
    }
    
    func write<T:Storable>(_ values:inout [T], for key:String) {
        let references = values.map {
            ValueTreeReference(uniqueIdentifier: $0.metadata.uniqueIdentifier, storedType: T.storedType)
        }
        valueTree.set(key, to: .valueTreeReferences(references))
    }
}

