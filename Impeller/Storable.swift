//
//  Storable.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias StorageType = String
public typealias StorableDictionary = [String:AnyStorablePrimitive]


public protocol Storable {
    var metadata: Metadata { get set }
    static var storageType: StorageType { get }
    
    init?(withStorage storage:StorageSource)
    mutating func store(in storage:StorageSink)
    
    func resolvedValue(forConflictWith newValue:Storable) -> Self
}


public extension Storable {
    func resolvedValue(forConflictWith newValue:Storable) -> Self {
        return self // Choose the local value by default
    }
    
    func isStorageEquivalent(to other:Storable) -> Bool {
        return storageRepresentation == other.storageRepresentation
    }
    
    var storageRepresentation: [String:AnyStorablePrimitive] {
        let builder = StorableDictionaryBuilder(self)
        return builder.representation
    }
}


fileprivate final class StorableDictionaryBuilder: StorageSink {
    private (set) var representation = StorableDictionary()
    
    init<T:Storable>(_ storable:T) {
        var s = storable
        s.store(in: self)
    }
    
    func store<T:StorablePrimitive>(_ value:T, for key:String) {
        representation[key] = AnyStorablePrimitive(value)
    }
    
    func store<T:StorablePrimitive>(_ value:T?, for key:String) {
        representation[key] = value != nil ? AnyStorablePrimitive(value!) : nil
    }
    
    func store<T:StorablePrimitive>(_ values:[T], for key:String) {
        representation[key] = AnyStorablePrimitive(values)
    }
    
    func store<T:Storable>(_ value:inout T, for key:String) {
        representation[key] = AnyStorablePrimitive(value.metadata.uniqueIdentifier)
    }
    
    func store<T:Storable>(_ value:inout T?, for key:String) {
        if let id = value?.metadata.uniqueIdentifier {
            representation[key] = AnyStorablePrimitive(id)
        }
        else {
            representation[key] = nil
        }
    }
    
    func store<T:Storable>(_ values:inout [T], for key:String) {
        representation[key] = AnyStorablePrimitive(values.map { $0.metadata.uniqueIdentifier })
    }
}

