//
//  Exchange.swift
//  Impeller
//
//  Created by Drew McCormack on 11/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

class Exchange {
    let localStorage: Storage
    let cloudStorage: CloudStorage
    
    init(couplingLocalStorage localStorage: Storage, to cloudStorage: CloudStorage) {
        self.localStorage = localStorage
        self.cloudStorage = cloudStorage
    }
    
    func exchange(completionHandler completion:CompletionHandler?) {
    }
}
