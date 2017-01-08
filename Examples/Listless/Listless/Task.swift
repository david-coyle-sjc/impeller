//
//  Task.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import Foundation
import Impeller

struct Task: Storable, Equatable {
    static var storedType: StoredType { return "Task" }
    
    var metadata = Metadata()
    var text = ""
    var tagList = TagList()
    var isComplete = false
    
    init() {}
    
    init?(withRepository repository:SourceRepository) {
        text = repository.value(for: Key.text.rawValue)!
        tagList = repository.value(for: Key.tagList.rawValue)!
        isComplete = repository.value(for: Key.isComplete.rawValue)!
    }
    
    mutating func store(in repository:SinkRepository) {
        repository.store(text, for: Key.text.rawValue)
        repository.store(&tagList, for: Key.tagList.rawValue)
        repository.store(isComplete, for: Key.isComplete.rawValue)
    }
    
    enum Key: String {
        case text, tagList, isComplete
    }
    
    static func == (left: Task, right: Task) -> Bool {
        return left.text == right.text && left.tagList == right.tagList && left.isComplete == right.isComplete
    }
}
