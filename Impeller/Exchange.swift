//
//  Exchange.swift
//  Impeller
//
//  Created by Drew McCormack on 11/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

typealias ExchangableLocalStorage = Storage & ExchangableStorage

class Exchange {
    let localStorage: ExchangableLocalStorage
    let cloudStorage: CloudStorage
    
    init(localStorage: ExchangableLocalStorage, cloudStorage: CloudStorage) {
        self.localStorage = localStorage
        self.cloudStorage = cloudStorage
    }
    
    func exchange(completionHandler completion:CompletionHandler?) {
    }
}
