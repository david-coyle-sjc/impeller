//
//  StorablePrimitive.swift
//  Impeller
//
//  Created by Drew McCormack on 14/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

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


public struct Null: StorablePrimitive {
    
    public init() {}
    
    public init?(withStorableValue value: Any) {
        if let value = value as? String, value == "<<NULL>>" {
            self.init()
        }
        else {
            return nil
        }
    }
    
    public var storableValue: Any { return "<<NULL>>" }
    
    public static func ==(left: Null, right: Null) -> Bool {
        return true
    }
}


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
