//
//  ExchangeTests.swift
//  Impeller
//
//  Created by Drew McCormack on 27/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import XCTest
@testable import Impeller

class ExchangeTests: XCTestCase {
    
    var storage1: MemoryStorage!
    var storage2: MemoryStorage!
    var exchange: Exchange!

    override func setUp() {
        super.setUp()
        storage1 = MemoryStorage()
        storage2 = MemoryStorage()
        exchange = Exchange(coupling: [storage1, storage2], pathForSavedState: nil)
    }
    
    func testOneWayExchange() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        storage1.save(&person)

        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        let personInStorage2:Person = storage2.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)!
        XCTAssertEqual(personInStorage2.metadata, person.metadata)
        XCTAssertEqual(personInStorage2.name, person.name)
    }
    
    func testTwoWayExchange() {
        var personInStorage1 = Person()
        personInStorage1.name = "Bob"
        personInStorage1.age = 10
        storage1.save(&personInStorage1)
        
        let expectation1 = self.expectation(description: "exchange1")
        exchange.exchange { error in
            expectation1.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        var personInStorage2:Person = storage2.fetchValue(identifiedBy: personInStorage1.metadata.uniqueIdentifier)!
        personInStorage2.name = "Tom"
        storage2.save(&personInStorage2)
        
        let expectation2 = self.expectation(description: "exchange2")
        exchange.exchange { error in
            expectation2.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        personInStorage1 = storage1.fetchValue(identifiedBy: personInStorage1.metadata.uniqueIdentifier)!
        XCTAssertEqual(personInStorage1.metadata, personInStorage2.metadata)
        XCTAssertEqual(personInStorage2.name, "Tom")
        XCTAssertEqual(personInStorage1.name, "Tom")
    }
    
    func testSimultaneousChangesExchange() {
        var personInStorage1 = Person()
        personInStorage1.name = "Bob"
        personInStorage1.age = 10
        storage1.save(&personInStorage1)
        
        var personInStorage2 = Person()
        personInStorage2.name = "Tom"
        personInStorage2.age = 20
        storage2.save(&personInStorage2)
        
        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        let idOfBob = personInStorage1.metadata.uniqueIdentifier
        let idOfTom = personInStorage2.metadata.uniqueIdentifier
        personInStorage1 = storage1.fetchValue(identifiedBy: idOfTom)!
        personInStorage2 = storage2.fetchValue(identifiedBy: idOfTom)!
        
        XCTAssertEqual(personInStorage1.metadata, personInStorage2.metadata)
        XCTAssertEqual(personInStorage2.name, "Tom")
        XCTAssertEqual(personInStorage1.name, "Tom")
        
        personInStorage1 = storage1.fetchValue(identifiedBy: idOfBob)!
        personInStorage2 = storage2.fetchValue(identifiedBy: idOfBob)!
        
        XCTAssertEqual(personInStorage1.metadata, personInStorage2.metadata)
        XCTAssertEqual(personInStorage2.name, "Bob")
        XCTAssertEqual(personInStorage1.name, "Bob")
    }
    
    func testConflictingChangesExchange() {
        var personInStorage1 = Person()
        personInStorage1.name = "Bob"
        personInStorage1.age = 10
        storage1.save(&personInStorage1)
        
        var personInStorage2 = Person()
        let newMetadata = Metadata(uniqueIdentifier: personInStorage1.metadata.uniqueIdentifier)
        personInStorage2.metadata = newMetadata
        personInStorage2.name = "Tom"
        personInStorage2.age = 20
        storage2.save(&personInStorage2)
        
        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        let id = personInStorage2.metadata.uniqueIdentifier
        personInStorage1 = storage1.fetchValue(identifiedBy: id)!
        personInStorage2 = storage2.fetchValue(identifiedBy: id)!
        
        XCTAssertEqual(personInStorage1.metadata.uniqueIdentifier, id)
        XCTAssertEqual(personInStorage2.metadata.uniqueIdentifier, id)
        XCTAssertEqual(personInStorage1.metadata, personInStorage2.metadata)
        XCTAssertEqual(personInStorage2.name, "Tom")
        XCTAssertEqual(personInStorage1.name, "Tom")
    }
    
    func testCursorsUpdate() {
        var personInStorage1 = Person()
        personInStorage1.name = "Bob"
        personInStorage1.age = 10
        storage1.save(&personInStorage1)
        
        XCTAssertNil(exchange.cursor(forExchangableIdentifiedBy: storage1.uniqueIdentifier))
        XCTAssertNil(exchange.cursor(forExchangableIdentifiedBy: storage2.uniqueIdentifier))

        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        XCTAssertNotNil(exchange.cursor(forExchangableIdentifiedBy: storage1.uniqueIdentifier))
        XCTAssertNotNil(exchange.cursor(forExchangableIdentifiedBy: storage2.uniqueIdentifier))
    }
}
