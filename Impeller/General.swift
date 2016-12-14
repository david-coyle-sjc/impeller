//
//  General.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

typealias CompletionHandler = ((Error?) -> Void)

public struct AnyEquatable: Equatable {
    fileprivate let value: Any
    fileprivate let equals: (Any) -> Bool
    
    public init<E: Equatable>(_ value: E) {
        self.value = value
        self.equals = {
            (($0 as? E) == value) 
        }
    }
}

public func ==(lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
    return lhs.equals(rhs.value)
}
