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
    
    var repository1: MemoryRepository!
    var repository2: MemoryRepository!
    var exchange: Exchange!

    override func setUp() {
        super.setUp()
        repository1 = MemoryRepository()
        repository2 = MemoryRepository()
        exchange = Exchange(coupling: [repository1, repository2], pathForSavedState: nil)
    }
    
    func testOneWayExchange() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        repository1.commit(&person)

        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        let personInRepository2:Person = repository2.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)!
        XCTAssertEqual(personInRepository2.metadata, person.metadata)
        XCTAssertEqual(personInRepository2.name, person.name)
    }
    
    func testTwoWayExchange() {
        var personInRepository1 = Person()
        personInRepository1.name = "Bob"
        personInRepository1.age = 10
        repository1.commit(&personInRepository1)
        
        let expectation1 = self.expectation(description: "exchange1")
        exchange.exchange { error in
            expectation1.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        var personInRepository2:Person = repository2.fetchValue(identifiedBy: personInRepository1.metadata.uniqueIdentifier)!
        personInRepository2.name = "Tom"
        repository2.commit(&personInRepository2)
        
        let expectation2 = self.expectation(description: "exchange2")
        exchange.exchange { error in
            expectation2.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        personInRepository1 = repository1.fetchValue(identifiedBy: personInRepository1.metadata.uniqueIdentifier)!
        XCTAssertEqual(personInRepository1.metadata, personInRepository2.metadata)
        XCTAssertEqual(personInRepository2.name, "Tom")
        XCTAssertEqual(personInRepository1.name, "Tom")
    }
    
    func testSimultaneousChangesExchange() {
        var personInRepository1 = Person()
        personInRepository1.name = "Bob"
        personInRepository1.age = 10
        repository1.commit(&personInRepository1)
        
        var personInRepository2 = Person()
        personInRepository2.name = "Tom"
        personInRepository2.age = 20
        repository2.commit(&personInRepository2)
        
        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        let idOfBob = personInRepository1.metadata.uniqueIdentifier
        let idOfTom = personInRepository2.metadata.uniqueIdentifier
        personInRepository1 = repository1.fetchValue(identifiedBy: idOfTom)!
        personInRepository2 = repository2.fetchValue(identifiedBy: idOfTom)!
        
        XCTAssertEqual(personInRepository1.metadata, personInRepository2.metadata)
        XCTAssertEqual(personInRepository2.name, "Tom")
        XCTAssertEqual(personInRepository1.name, "Tom")
        
        personInRepository1 = repository1.fetchValue(identifiedBy: idOfBob)!
        personInRepository2 = repository2.fetchValue(identifiedBy: idOfBob)!
        
        XCTAssertEqual(personInRepository1.metadata, personInRepository2.metadata)
        XCTAssertEqual(personInRepository2.name, "Bob")
        XCTAssertEqual(personInRepository1.name, "Bob")
    }
    
    func testConflictingChangesExchange() {
        var personInRepository1 = Person()
        personInRepository1.name = "Bob"
        personInRepository1.age = 10
        repository1.commit(&personInRepository1)
        
        var personInRepository2 = Person()
        let newMetadata = Metadata(uniqueIdentifier: personInRepository1.metadata.uniqueIdentifier)
        personInRepository2.metadata = newMetadata
        personInRepository2.name = "Tom"
        personInRepository2.age = 20
        repository2.commit(&personInRepository2)
        
        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        let id = personInRepository2.metadata.uniqueIdentifier
        personInRepository1 = repository1.fetchValue(identifiedBy: id)!
        personInRepository2 = repository2.fetchValue(identifiedBy: id)!
        
        XCTAssertEqual(personInRepository1.metadata.uniqueIdentifier, id)
        XCTAssertEqual(personInRepository2.metadata.uniqueIdentifier, id)
        XCTAssertEqual(personInRepository1.metadata, personInRepository2.metadata)
        XCTAssertEqual(personInRepository2.name, "Tom")
        XCTAssertEqual(personInRepository1.name, "Tom")
    }
    
    func testCursorsUpdate() {
        var personInRepository1 = Person()
        personInRepository1.name = "Bob"
        personInRepository1.age = 10
        repository1.commit(&personInRepository1)
        
        XCTAssertNil(exchange.cursor(forExchangableIdentifiedBy: repository1.uniqueIdentifier))
        XCTAssertNil(exchange.cursor(forExchangableIdentifiedBy: repository2.uniqueIdentifier))

        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0.5)
        
        XCTAssertNotNil(exchange.cursor(forExchangableIdentifiedBy: repository1.uniqueIdentifier))
        XCTAssertNotNil(exchange.cursor(forExchangableIdentifiedBy: repository2.uniqueIdentifier))
    }
}
