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
    
    init?(readingFrom repository:ReadRepository) {
        text = repository.read(Key.text.rawValue)!
        tagList = repository.read(Key.tagList.rawValue)!
        isComplete = repository.read(Key.isComplete.rawValue)!
    }
    
    mutating func write(in repository:WriteRepository) {
        repository.write(text, for: Key.text.rawValue)
        repository.write(&tagList, for: Key.tagList.rawValue)
        repository.write(isComplete, for: Key.isComplete.rawValue)
    }
    
    enum Key: String {
        case text, tagList, isComplete
    }
    
    static func == (left: Task, right: Task) -> Bool {
        return left.text == right.text && left.tagList == right.tagList && left.isComplete == right.isComplete
    }
}
