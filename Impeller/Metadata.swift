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
        
    public private(set) var uniqueIdentifier: UniqueIdentifier
    public internal(set) var timestamp: TimeInterval // When stored
    var version: StorageVersion = 0
    
    public init(uniqueIdentifier: UniqueIdentifier = UUID().uuidString) {
        self.uniqueIdentifier = uniqueIdentifier
        self.timestamp = Date.timeIntervalSinceReferenceDate
    }
    
    public init?(withStorage storage:Storage) {
        if  let v:StorageVersion = storage.value(for: "version"),
            let t:TimeInterval = storage.value(for: "timestamp"),
            let i:UniqueIdentifier = storage.value(for: "uniqueIdentifier") {
            version = v
            timestamp = t
            uniqueIdentifier = i
        }
        else {
            return nil
        }
    }
    
    func store(in storage:Storage) {
        storage.store(version, for: "version")
        storage.store(timestamp, for: "timestamp")
        storage.store(uniqueIdentifier, for: "uniqueIdentifier")
    }
    
    public static func == (left: Metadata, right: Metadata) -> Bool {
        return left.version == right.version && left.timestamp == right.timestamp && left.uniqueIdentifier == right.uniqueIdentifier
    }
    
}
