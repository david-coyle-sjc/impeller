//
//  Primitive.swift
//  Impeller
//
//  Created by Drew McCormack on 30/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias PrimitiveType = Int

public enum Primitive : Equatable {
    case string(String)
    case int(Int)
    case float(Float)
    case bool(Bool)
    case data(Data)
    
    public init?<T>(value:T) {
        switch T.self {
        case is String.Type:
            self = .string(value as! String)
        case is Int.Type:
            self = .int(value as! Int)
        case is Float.Type:
            self = .float(value as! Float)
        case is Bool.Type:
            self = .bool(value as! Bool)
        case is Data.Type:
            self = .data(value as! Data)
        default:
            return nil
        }
    }
    
    public init?(type: PrimitiveType, value: Any) {
        switch type {
        case 10:
            guard let value = value as? String else { return nil }
            self = .string(value)
        case 20:
            guard let value = value as? Int else { return nil }
            self = .int(value)
        case 30:
            guard let value = value as? Float else { return nil }
            self = .float(value)
        case 40:
            guard let value = value as? Bool else { return nil }
            self = .bool(value)
        case 50:
            guard let value = value as? Data else { return nil }
            self = .data(value)
        default:
            return nil
        }
    }
    
    public var type: PrimitiveType {
        switch self {
        case .string:
            return 10
        case .int:
            return 20
        case .float:
            return 30
        case .bool:
            return 30
        case .data:
            return 30
        }
    }
    
    public static func ==(left: Primitive, right: Primitive) -> Bool {
        switch (left, right) {
        case let (.int(l), .int(r)):
            return l == r
        case let (.string(l), .string(r)):
            return l == r
        case let (.float(l), .float(r)):
            return l == r
        case let (.bool(l), .bool(r)):
            return l == r
        case let (.data(l), .data(r)):
            return l == r
        default:
            return false
        }
    }
}
