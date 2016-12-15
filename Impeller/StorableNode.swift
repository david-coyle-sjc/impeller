//
//  StorableNode.swift
//  Impeller
//
//  Created by Drew McCormack on 15/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias StorableNode = [String:AnyStorablePrimitive]

final class StorableNodeBuilder: StorageSink {
    private (set) var storableNode = StorableNode()
    
    init<T:Storable>(_ storable:T) {
        var s = storable
        s.store(in: self)
    }
    
    func store<T:StorablePrimitive>(_ value:T, for key:String) {
        storableNode[key] = AnyStorablePrimitive(value)
    }
    
    func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        storableNode[key] = value != nil ? AnyStorablePrimitive(value!) : nil
    }
    
    func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        storableNode[key] = AnyStorablePrimitive(values)
    }
    
    func store<T:Storable>(_ value:inout T, for key:String) {
        storableNode[key] = AnyStorablePrimitive(value.metadata.uniqueIdentifier)
    }
    
    func store<T:Storable>(_ value:inout T?, for key:String) {
        if let id = value?.metadata.uniqueIdentifier {
            storableNode[key] = AnyStorablePrimitive(id)
        }
        else {
            storableNode[key] = nil
        }
    }
    
    func store<T:Storable>(_ values:inout [T], for key:String) {
        storableNode[key] = AnyStorablePrimitive(values.map { $0.metadata.uniqueIdentifier })
    }
}

