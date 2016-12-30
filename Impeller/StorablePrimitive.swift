//
//  StorablePrimitive.swift
//  Impeller
//
//  Created by Drew McCormack on 14/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public protocol StorablePrimitive {
    init?(_ primitive: Primitive)
    var primitive: Primitive { get }
}

extension String: StorablePrimitive {
    public init?(_ primitive: Primitive) {
        switch primitive {
        case .string(let s):
            self = s
        default:
            return nil
        }
    }

    public var primitive: Primitive {
        return .string(self)
    }
}

extension Int: StorablePrimitive {
    public init?(_ primitive: Primitive) {
        switch primitive {
        case .int(let i):
            self = i
        default:
            return nil
        }
    }
    
    public var primitive: Primitive {
        return .int(self)
    }
}

extension Float: StorablePrimitive {
    public init?(_ primitive: Primitive) {
        switch primitive {
        case .float(let f):
            self = f
        default:
            return nil
        }
    }
    
    public var primitive: Primitive {
        return .float(self)
    }
}

extension Bool: StorablePrimitive {
    public init?(_ primitive: Primitive) {
        switch primitive {
        case .bool(let b):
            self = b
        default:
            return nil
        }
    }
    
    public var primitive: Primitive {
        return .bool(self)
    }
}

extension Data: StorablePrimitive {
    public init?(_ primitive: Primitive) {
        switch primitive {
        case .data(let d):
            self = d
        default:
            return nil
        }
    }
    
    public var primitive: Primitive {
        return .data(self)
    }
}

