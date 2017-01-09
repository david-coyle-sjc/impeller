//
//  Tags.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import Foundation
import Impeller

struct TagList: Storable, Equatable {
    static var storedType: StoredType { return "TagList" }
    
    var metadata = Metadata()
    var tags: [String] = []
    var asString: String {
        return tags.joined(separator: " ")
    }
    
    init() {}
    
    init(fromText text:String) {
        let newTags = text.characters.split { $0 == " " }.map { String($0) }.filter { $0.characters.count > 0 }
        tags = Array(Set(newTags)).sorted()
    }
    
    init?(withRepository repository:SourceRepository) {
        tags = repository.values(for: Key.tags.rawValue)!
    }
    
    mutating func store(in repository:SinkRepository) {
        repository.store(tags, for: Key.tags.rawValue)
    }
    
    enum Key: String {
        case tags
    }
    
    static func ==(left: TagList, right: TagList) -> Bool {
        return left.tags == right.tags
    }
}
