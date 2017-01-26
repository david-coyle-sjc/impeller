//
//  JSONRepository.swift
//  Impeller
//
//  Created by Drew McCormack on 26/01/2017.
//  Copyright © 2017 Drew McCormack. All rights reserved.
//

import Foundation

public class JSONSerializer: Serializer {
    
    public func load(from url:URL) throws -> [String:ValueTree] {
        fatalError("JSON serialization not implemented yet")
    }
    
    public func save(_ valueTreesByKey:[String:ValueTree], to url:URL) throws {
        fatalError("JSON serialization not implemented yet")
    }
    
}
