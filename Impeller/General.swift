//
//  General.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias CompletionHandler = ((Error?) -> Void)

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

func uuid() -> String {
    var data = Data(count: 16)
    data.withUnsafeMutableBytes { uuid_generate_random($0) }

    var result = ""
    let hypenIndexes = [3,5,7,9]
    for (index, byte) in data.enumerated() {
        let next = String(byte, radix: 16, uppercase: true)
        let lead = next.characters.count == 1 ? "0" : ""
        let trail = hypenIndexes.contains(index) ? "-" : ""
        result += lead + next + trail
    }
    
    return result
}

extension Dictionary {
    func setting(_ value: Value, for key: Key) -> [Key:Value] {
        var result = self
        result[key] = value
        return result
    }
    
    func mapValues<T>(transform:(Value)->T) -> Dictionary<Key, T> {
        var d = Dictionary<Key,T>()
        for (key, value) in self {
            d[key] = transform(value)
        }
        return d
    }
}
