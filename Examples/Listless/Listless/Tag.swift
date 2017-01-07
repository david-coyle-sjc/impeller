//
//  Tag.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import Foundation
import Impeller

struct Tag: Storable {
    static var storedType: StoredType { return "Tag" }
    
    var metadata = Metadata()
    let text: String
    
    init(_ text: String) {
        self.metadata = Metadata(uniqueIdentifier: "Tag__" + text)
        self.text = text
    }
    
    init?(withRepository repository:SourceRepository) {
        text = repository.value(for: Key.text.rawValue)!
    }
    
    mutating func store(in repository:SinkRepository) {
        repository.store(text, for: Key.text.rawValue)
    }
    
    enum Key: String {
        case text
    }
}
