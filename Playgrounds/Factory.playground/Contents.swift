
typealias StorableFactory = (Int)->Any

protocol Storable: Equatable {
    static var name: String { get }
    init(age: Int)
}

struct Person: Storable {
    var age: Int = 0
    init(age: Int) {
        self.age = age
    }
    static var name: String { return "Person" }
}

struct Child: Storable {
    let age: Int = 0
    init(age: Int) {
    }
    static var name: String { return "Child" }
}

func == (left: Person, right: Person) -> Bool {
    return left.age == right.age
}

func == (left: Child, right: Child) -> Bool {
    return left.age == right.age
}

class Storage {
    var factoryForName = [String:StorableFactory]()

    func register<T:Storable>(type:T.Type) {
        factoryForName[T.name] = T.init
    }
    
    func makeValue(forTypeName type: String, age: Int) -> Any {
        return factoryForName[type]!(age)
    }
}

let storage = Storage()
storage.register(type: Person.self)
storage.register(type: Child.self)

var p = storage.makeValue(forTypeName: "Person", age: 20) as! Person
p.age

var c = storage.makeValue(forTypeName: "Child", age: 1) as! Child
c.age