//: Playground - noun: a place where people can play

import UIKit

protocol Storable {
    static var name: String { get }
    init(age: Int)
}

extension Storable {
    func hash() {}
}

protocol Storage : class {
    var types: [Storable.Type]? { get set }
}

struct Person : Storable {
    let age: Int = 0
    init(age: Int) {
    }
    static var name: String { return "Person" }
}

struct Child : Storable {
    let age: Int = 0
    init(age: Int) {
    }
    static var name: String { return "Child" }
}

let storableTypes:[Storable.Type] = [Person.self, Child.self]
var storableTypeByName = [String:Storable.Type]()

for s in storableTypes {
    storableTypeByName[s.name] = s
}

func create(for name:String) -> Storable? {
    if let t = storableTypeByName[name] {
        return t.init(age: 10)
    }
    return nil
}

create(for: "Child")
create(for: "Person")
create(for: "Elephant")
