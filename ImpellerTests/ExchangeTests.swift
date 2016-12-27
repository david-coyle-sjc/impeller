//
//  ExchangeTests.swift
//  Impeller
//
//  Created by Drew McCormack on 27/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import XCTest
import Impeller

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
    
    func testDataIsExchanged() {
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
    
}
