//
//  Storable.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias StorageType = String


public protocol Storable {
    var metadata: Metadata { get set }
    static var storageType: StorageType { get }
    
    init?(withStorage storage:StorageSource)
    mutating func store(in storage:StorageSink)
    
    func resolvedValue(forConflictWith newValue:Storable, context: Any?) -> Self
}


public extension Storable {
    func resolvedValue(forConflictWith newValue:Storable, context: Any? = nil) -> Self {
        return self // Choose the local value by default
    }
    
    func isStorageEquivalent(to other:Storable) -> Bool {
        return valueTree == other.valueTree
    }
    
    var valueTree: ValueTree {
        let builder = ValueTreeBuilder(self)
        return builder.valueTree
    }
}

