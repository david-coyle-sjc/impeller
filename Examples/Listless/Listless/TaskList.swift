//
//  TaskList.swift
//  Listless
//
//  Created by Drew McCormack on 07/01/2017.
//  Copyright © 2017 The Mental Faculty B.V. All rights reserved.
//

import Foundation
import Impeller

struct TaskList: Storable, Equatable {
    static var storedType: StoredType { return "TaskList" }
    
    var metadata = Metadata()
    var tasks:[Task] = []
    
    init() {}
    
    init?(readingFrom repository:ReadRepository) {
        tasks = repository.read(Key.tasks.rawValue)!
    }
    
    mutating func write(in repository:WriteRepository) {
        repository.write(&tasks, for: Key.tasks.rawValue)
    }
    
    enum Key: String {
        case tasks
    }
    
    static func == (left: TaskList, right: TaskList) -> Bool {
        return left.tasks == right.tasks
    }
}
