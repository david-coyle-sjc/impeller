//
//  Storable.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias StorageType = String


//public protocol Storable: Hashable {
public protocol Storable {
    var metadata: Metadata { get set }
    static var storageType: StorageType { get }
    
    init?(withStorage storage:Storage)
    mutating func store(in storage:Storage)
    
    func resolvedValue(forConflictWith newValue:Self) -> Self
}

public extension Storable {
    func resolvedValue(forConflictWith newValue:Self) -> Self {
        // Choose the local value by default
        return self
    }
    
//    var hashValue: Int {
//        return metadata.uniqueIdentifier.hash
//    }
}


public protocol StorablePrimitive: Equatable {
    init?(withStorableValue value: Any)
    var storableValue: Any { get }
}

public extension StorablePrimitive {
    init?(withStorableValue value: Any) {
        if let value = value as? Self {
            self = value
        }
        else {
            return nil
        }
    }
    
    var storableValue: Any {
        return self
    }
}

extension String: StorablePrimitive {}
extension Int: StorablePrimitive {}
extension UInt64: StorablePrimitive {}
extension Float: StorablePrimitive {}
extension Double: StorablePrimitive {}
