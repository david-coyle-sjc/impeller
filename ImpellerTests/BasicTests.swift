//
//  ImpellerTests.swift
//  ImpellerTests
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import XCTest
@testable import Impeller

class BasicTests: XCTestCase {
    
    var repository: MonolithicRepository!
    
    override func setUp() {
        repository = MonolithicRepository()
    }
    
    func testSave() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        person.tags.append("Tag")
        
        repository.commit(&person)
        
        XCTAssertEqual(person.name, "Bob")
        XCTAssertEqual(person.age, 10)
        XCTAssertEqual(person.tags, ["Tag"])
    }
    
    func testFetch() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        person.tags = ["tag"]
        
        repository.commit(&person)
        
        let fetchedPerson:Person? = repository.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedPerson!.name, "Bob")
        XCTAssertEqual(fetchedPerson!.age, 10)
        XCTAssertEqual(fetchedPerson!.tags, ["tag"])
    }
    
    func testUpdateBumpsVersion() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        XCTAssertEqual(person.metadata.version, 0)

        repository.commit(&person)
        XCTAssertEqual(person.metadata.version, 0)
        
        person.name = "Dave"
        repository.commit(&person)
        XCTAssertEqual(person.metadata.version, 1)
    }
    
    func testSaveWithNoChangeDoesNotChangeMetadata() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        repository.commit(&person)
        
        let metadata = person.metadata
        repository.commit(&person)
        XCTAssertEqual(metadata, person.metadata)
    }
    
    func testStoringNilProperty() {
        var person = Person()
        person.name = "Bob"
        person.age = nil
        repository.commit(&person)
        
        let fetchedPerson:Person? = repository.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)
        XCTAssertNil(fetchedPerson!.age)
    }
    
    func testParentWithChild() {
        var parent = Parent()
        parent.child.age = 10
        repository.commit(&parent)

        let fetchedChild:Child! = repository.fetchValue(identifiedBy: parent.child.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedChild.age, 10)

        let fetchedParent:Parent! = repository.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedParent.child.age, 10)
    }
    
    func testChangingChildInrepositoryChangesFetchedParent() {
        var parent = Parent()
        parent.child.age = 10
        repository.commit(&parent)
        
        var child:Child? = repository.fetchValue(identifiedBy: parent.child.metadata.uniqueIdentifier)
        child!.age = 20
        repository.commit(&child!)
        
        XCTAssertEqual(parent.child.age, 10)
        XCTAssertEqual(child!.age, 20)

        let fetchedParent:Parent! = repository.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedParent.child.age, 20)
    }
    
    func testChangingChildButSavingParent() {
        var parent = Parent()
        parent.child.age = 10
        repository.commit(&parent)
        XCTAssertEqual(parent.child.age, 10)

        parent.child.age = 20
        XCTAssertEqual(parent.child.age, 20)

        repository.commit(&parent)
        XCTAssertEqual(parent.child.age, 20)

        let child:Child? = repository.fetchValue(identifiedBy: parent.child.metadata.uniqueIdentifier)
        XCTAssertEqual(child!.age, 20)
    }
    
    func testResolvingConflicts() {
        var child = Child()
        child.age = 10
        repository.commit(&child)
    
        // Update and set metadata to preceed repositoryd value
        child.age = 20
        child.metadata.timestamp -= 1.0
        child.metadata.version += 1
        repository.commit(&child)
        
        // Ensure the repositoryd values survive, due to having more recent timestamp
        XCTAssertEqual(child.age, 10)
        
        // Now set to later timestamp and commit
        child.age = 20
        child.metadata.timestamp += 1.0
        child.metadata.version += 1
        repository.commit(&child)
        
        // Ensure the repositoryd values are updated
        XCTAssertEqual(child.age, 20)
    }
    
    func testArrayOfChildObjects() {
        var parent = Parent()
        var child1 = Child() ; child1.age = 10
        var child2 = Child() ; child2.age = 12
        parent.children = [child1, child2]
        repository.commit(&parent)
        
        let fetchedParent:Parent? = repository.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedParent!.children.count, 2)
        
        let fetchedChild2 = fetchedParent?.children[1]
        XCTAssertEqual(fetchedChild2!.age, 12)
    }
    
    func testChangingChildrenDeletesOrphans() {
        var parent = Parent()
        let child1 = Child()
        let child2 = Child()
        parent.children = [child1, child2]
        repository.commit(&parent)
        
        do {
            let fetchedChild:Child? = repository.fetchValue(identifiedBy: child2.metadata.uniqueIdentifier)
            XCTAssertNotNil(fetchedChild)
        }
        
        let child3 = Child()
        parent.children = [child1, child3]
        repository.commit(&parent)
        
        do {
            let fetchedChild:Child? = repository.fetchValue(identifiedBy: child2.metadata.uniqueIdentifier)
            XCTAssertNil(fetchedChild)
        }
    }
    
    func testDeletingParentDeletesChildren() {
        var parent = Parent()
        let child1 = Child()
        let child2 = Child()
        parent.children = [child1, child2]
        repository.commit(&parent)
        
        repository.delete(&parent)
        
        let fetchedChild:Child? = repository.fetchValue(identifiedBy: child1.metadata.uniqueIdentifier)
        XCTAssertNil(fetchedChild)
    }
    
    func testChangingChildToSameChildDoesNotOrphan() {
        var parent = Parent()
        parent.children = [Child()]
        repository.commit(&parent)
        
        var child1 = parent.child
        child1.age = 13
        parent.children = [child1]
        repository.commit(&parent)

        let fetchedChild:Child? = repository.fetchValue(identifiedBy: child1.metadata.uniqueIdentifier)
        XCTAssertNotNil(fetchedChild)
    }
}



