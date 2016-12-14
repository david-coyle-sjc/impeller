//
//  Storable.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias StorageType = String
public typealias DictionaryRepresentation = [String:AnyStorablePrimitive]


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
        let builder = DictionaryRepresentationBuilder(self)
        return builder.representation
    }
}

final class DictionaryRepresentationBuilder: StorageSink {
    private (set) var representation = DictionaryRepresentation()
    
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
    
    func store<T:Storable>(_ value:inout T, for key:String) {}
    func store<T:Storable>(_ value:inout T?, for key:String) {}
    func store<T:Storable>(_ values:inout [T], for key:String) {}
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
    
    init<S: StorablePrimitive>(_ values: [S]) {
        self.value = values
        self.capturedEquals = { ((($0 as? [S]) ?? []) == values) }
        self.capturedStorableValue = { values.map { $0.storableValue } }
    }
    
    public var storableValue: Any {
        return self.capturedStorableValue()
    }
}

public func ==(left: AnyStorablePrimitive, right: AnyStorablePrimitive) -> Bool {
    return left.capturedEquals(right.value)
}
