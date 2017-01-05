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
    
    var localRepository1: MemoryRepository!
    var localRepository2: MemoryRepository!
    var cloudRepository: CloudKitRepository!
    var exchange1: Exchange!
    var exchange2: Exchange!

    override func setUp() {
        localRepository1 = MemoryRepository()
        localRepository2 = MemoryRepository()
        
        let database = CKContainer.default().privateCloudDatabase
        cloudRepository = CloudKitRepository(withUniqueIdentifier: "Main", cloudDatabase: database)
        
        exchange1 = Exchange(coupling: [localRepository1, cloudRepository], pathForSavedState: nil)
        exchange2 = Exchange(coupling: [localRepository2, cloudRepository], pathForSavedState: nil)
    }
 
    func testOneWayExchange() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        localRepository1.save(&person)
        
        // Upload
        var expectation = self.expectation(description: "exchange1")
        exchange1.exchange { error in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5.0)
        
        // Download
        expectation = self.expectation(description: "exchange2")
        exchange2.exchange { error in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5.0)
        
        let personInRepository2:Person = localRepository2.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)!
        XCTAssertEqual(personInRepository2.metadata, person.metadata)
        XCTAssertEqual(personInRepository2.name, person.name)
    }
}
