//
//  Metadata.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias UniqueIdentifier = String
typealias StorageVersion = UInt64

public struct Metadata: Equatable {
    
    public enum Key: String {
        case version, timestamp, uniqueIdentifier
    }
        
    public let uniqueIdentifier: UniqueIdentifier
    public internal(set) var timestamp: TimeInterval // When stored
    var version: StorageVersion = 0
    
    public init(uniqueIdentifier: UniqueIdentifier = UUID().uuidString) {
        self.uniqueIdentifier = uniqueIdentifier
        self.timestamp = Date.timeIntervalSinceReferenceDate
    }
    
    public init?(withStorage storage:Storage) {
        if  let v:StorageVersion = storage.value(for: Key.version.rawValue),
            let t:TimeInterval = storage.value(for: Key.timestamp.rawValue),
            let i:UniqueIdentifier = storage.value(for: Key.uniqueIdentifier.rawValue) {
            version = v
            timestamp = t
            uniqueIdentifier = i
        }
        else {
            return nil
        }
    }
    
    func store(in storage:Storage) {
        storage.store(version, for: Key.version.rawValue)
        storage.store(timestamp, for: Key.timestamp.rawValue)
        storage.store(uniqueIdentifier, for: Key.uniqueIdentifier.rawValue)
    }
    
    public static func == (left: Metadata, right: Metadata) -> Bool {
        return left.version == right.version && left.timestamp == right.timestamp && left.uniqueIdentifier == right.uniqueIdentifier
    }
    
}
