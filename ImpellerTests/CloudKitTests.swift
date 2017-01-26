//
//  CloudKitTests.swift
//  Impeller
//
//  Created by Drew McCormack on 05/01/2017.
//  Copyright © 2017 Drew McCormack. All rights reserved.
//

import XCTest
import CloudKit
import Impeller

class CloudKitTests: XCTestCase {
    
    var localRepository1: MonolithicRepository!
    var localRepository2: MonolithicRepository!
    var cloudRepository: CloudKitRepository!
    var exchange1: Exchange!
    var exchange2: Exchange!

    override func setUp() {
        super.setUp()
        
        localRepository1 = MonolithicRepository()
        localRepository2 = MonolithicRepository()
        
        let database = CKContainer.default().privateCloudDatabase
        cloudRepository = CloudKitRepository(withUniqueIdentifier: "Main", cloudDatabase: database)
        
        exchange1 = Exchange(coupling: [localRepository1, cloudRepository], pathForSavedState: nil)
        exchange2 = Exchange(coupling: [localRepository2, cloudRepository], pathForSavedState: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        let expectation = self.expectation(description: "removeZone")
        cloudRepository.removeZone { error in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5.0)
    }
    
    func performExchange(for exchange: Exchange) {
        let expectation = self.expectation(description: "exchange")
        exchange.exchange { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5.0)
    }
    
    func testOneWayExchange() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        person.tags = ["friends"]
        localRepository1.commit(&person)
        
        performExchange(for: exchange1)
        performExchange(for: exchange2)
        
        let personInRepository2:Person = localRepository2.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)!
        XCTAssertEqual(personInRepository2.metadata, person.metadata)
        XCTAssertEqual(personInRepository2.name, person.name)
        XCTAssertEqual(personInRepository2.age, person.age)
        XCTAssertEqual(personInRepository2.tags, person.tags)
    }
    
    func testExchangeWithChildren() {
        var parent = Parent()
        parent.children = [Child()]
        parent.child.age = 30
        localRepository1.commit(&parent)
        
        performExchange(for: exchange1)
        performExchange(for: exchange2)
        
        let parentInRep2:Parent = localRepository2.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)!
        XCTAssertEqual(parentInRep2.child.age, 30)
    }
}
