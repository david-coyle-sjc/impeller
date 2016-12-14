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
    
    init?(withStorage storage:Storage)
    mutating func store(in storage:Storage)
    
    func resolvedValue(forConflictWith newValue:Storable) -> Self
}

public extension Storable {
    func resolvedValue(forConflictWith newValue:Self) -> Self {
        // Choose the local value by default
        return self
    }
    
    func isStorageEquivalent(to other:Storable) -> Bool {
        return storageRepresentation() == other.storageRepresentation()
    }
    
    func storageRepresentation() -> [String:AnyStorablePrimitive] {
        return [String:AnyStorablePrimitive]()
    }
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
extension Int64: StorablePrimitive {}
extension Int32: StorablePrimitive {}
extension Int16: StorablePrimitive {}
extension UInt: StorablePrimitive {}
extension UInt64: StorablePrimitive {}
extension UInt32: StorablePrimitive {}
extension UInt16: StorablePrimitive {}
extension Float: StorablePrimitive {}
extension Double: StorablePrimitive {}
extension Data: StorablePrimitive {}


public struct AnyStorablePrimitive: StorablePrimitive {
    fileprivate let value: Any
    fileprivate let capturedEquals: (Any) -> Bool
    fileprivate let capturedStorableValue: () -> Any
    
    init<S: StorablePrimitive>(_ value: S) {
        self.value = value
        self.capturedEquals = { (($0 as? S) == value) }
        self.capturedStorableValue = { value.storableValue }
    }
    
    public var storableValue: Any {
        return self.capturedStorableValue()
    }
}

public func ==(left: AnyStorablePrimitive, right: AnyStorablePrimitive) -> Bool {
    return left.capturedEquals(right)
}
