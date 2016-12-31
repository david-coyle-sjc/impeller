//
//  Property.swift
//  Impeller
//
//  Created by Drew McCormack on 30/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public enum PropertyType: Int {
    case primitive = 10
    case optionalPrimitive = 20
    case primitives = 30
    case valueTreeReference = 40
    case optionalValueTreeReference = 50
    case valueTreeReferences = 60
    
    public var isOptional: Bool {
        switch self {
        case .optionalPrimitive, .optionalValueTreeReference:
            return true
        default:
            return false
        }
    }
    
    public var isPrimitive: Bool {
        switch self {
        case .optionalPrimitive, .primitive, .primitives:
            return true
        default:
            return false
        }
    }
}


public enum Property: Equatable {
    
    case primitive(Primitive)
    case optionalPrimitive(Primitive?)
    case primitives([Primitive])
    case valueTreeReference(ValueTreeReference)
    case optionalValueTreeReference(ValueTreeReference?)
    case valueTreeReferences([ValueTreeReference])
    
    public var propertyType: PropertyType {
        switch self {
        case .primitive:
            return .primitive
        case .optionalPrimitive:
            return .optionalPrimitive
        case .primitives:
            return .primitives
        case .valueTreeReference:
            return .valueTreeReference
        case .optionalValueTreeReference:
            return .optionalValueTreeReference
        case .valueTreeReferences:
            return .valueTreeReferences
        }
    }
    
    public func asPrimitive() -> Primitive? {
        switch self {
        case .primitive(let v):
            return v
        default:
            return nil
        }
    }
    
    public func asOptionalPrimitive() -> Primitive?? {
        switch self {
        case .optionalPrimitive(let v):
            return v
        default:
            return nil
        }
    }
    
    public func asPrimitives() -> [Primitive]? {
        switch self {
        case .primitives(let v):
            return v
        default:
            return nil
        }
    }
    
    public func asValueTreeReference() -> ValueTreeReference? {
        switch self {
        case .valueTreeReference(let v):
            return v
        default:
            return nil
        }
    }
    
    public func asOptionalValueTreeReference() -> ValueTreeReference?? {
        switch self {
        case .optionalValueTreeReference(let v):
            return v
        default:
            return nil
        }
    }
    
    public func asValueTreeReferences() -> [ValueTreeReference]? {
        switch self {
        case .valueTreeReferences(let v):
            return v
        default:
            return nil
        }
    }
    
    public static func ==(left: Property, right: Property) -> Bool {
        switch (left, right) {
        case let (.primitive(l), .primitive(r)):
            return l == r
        case let (.optionalPrimitive(l), .optionalPrimitive(r)):
            return l == r
        case let (.primitives(l), .primitives(r)):
            return l == r
        case let (.valueTreeReference(l), .valueTreeReference(r)):
            return l == r
        case let (.optionalValueTreeReference(l), .optionalValueTreeReference(r)):
            return l == r
        case let (.valueTreeReferences(l), .valueTreeReferences(r)):
            return l == r
        default:
            return false
        }
    }
}
