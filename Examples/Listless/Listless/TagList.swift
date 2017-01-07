//
//  Tags.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import Foundation
import Impeller

struct TagList: Storable {
    static var storedType: StoredType { return "TagList" }
    
    var metadata = Metadata()
    var tags: [Tag] = []
    
    init() {}
    
    init(fromText text:String) {
        let strings = text.characters.split { $0 == " " }.map { String($0) }.filter { $0.characters.count > 0 }
        let tags = strings.map { Tag($0) }
    }
    
    init?(withRepository repository:SourceRepository) {
        tags = repository.values(for: Key.tags.rawValue)!
    }
    
    mutating func store(in repository:SinkRepository) {
        repository.store(&tags, for: Key.tags.rawValue)
    }
    
    var asString: String {
        return tags.map { $0.text }.joined(separator: " ")
    }
    
    enum Key: String {
        case tags
    }
}
