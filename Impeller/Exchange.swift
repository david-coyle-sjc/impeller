//
//  Exchange.swift
//  Impeller
//
//  Created by Drew McCormack on 11/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public protocol Cursor {
    var data: Data { get set }
}


public protocol Exchangable: class {
    
    var uniqueIdentifier: UniqueIdentifier { get }
    
    func push(changesSince cursor: Cursor?, completionHandler completion: @escaping (Error?, [ValueTree], Cursor?)->Void)
    func pull(_ ValueTrees: [ValueTree], completionHandler completion: @escaping CompletionHandler)
    
}


public class Exchange {
    public let exchangables: [Exchangable]
    public let pathForSavedState: String?
    private var cursorsByExchangableIdentifier: [UniqueIdentifier:Cursor]
    
    public init(coupling exchangables: [Exchangable], pathForSavedState: String?) {
        precondition(exchangables.count > 1)
        self.exchangables = exchangables
        self.pathForSavedState = pathForSavedState
        cursorsByExchangableIdentifier = [UniqueIdentifier:Cursor]()
    }
    
    func cursor(forExchangableIdentifiedBy identifier: UniqueIdentifier) -> Cursor? {
        return cursorsByExchangableIdentifier[identifier]
    }
    
    func save(_ cursor: Cursor?, forExchangableIdentifiedBy identifier: UniqueIdentifier) {
        cursorsByExchangableIdentifier[identifier] = cursor
    }
    
    public func exchange(completionHandler completion:CompletionHandler?) {
        let group = DispatchGroup()
        
        // Join group for each exchangable in outer loop. 
        // Avoid race conditions by doing this before starting loop.
        for e1 in exchangables { group.enter() }
        
        // When group is complete, call completion
        var returnError: Error?
        group.notify(queue: DispatchQueue.main) { [unowned self] in
            completion?(returnError)
        }
        
        for e1 in exchangables {
            let uniqueIdentifier = e1.uniqueIdentifier
            let c1 = cursor(forExchangableIdentifiedBy: uniqueIdentifier)
            e1.push(changesSince: c1) {
                error, dictionaries, newCursor in
                
                guard returnError == nil else {
                    group.leave()
                    return
                }
                guard error == nil else {
                    returnError = error
                    group.leave()
                    return
                }
                
                // Join groups for each other exchangable.
                let pullGroup = DispatchGroup()
                for e2 in self.exchangables {
                    guard e1 !== e2 else { continue }
                    pullGroup.enter()
                }
                
                // Save cursor if all stores successfully assimilate data
                pullGroup.notify(queue: DispatchQueue.main) {
                    defer { group.leave() }
                    guard returnError == nil else { return }
                    self.save(newCursor, forExchangableIdentifiedBy: uniqueIdentifier)
                }
                
                for e2 in self.exchangables {
                    guard e1 !== e2 else { continue }
                    e2.pull(dictionaries) {
                        error in
                        defer { pullGroup.leave() }
                        guard returnError == nil else { return }
                        guard error == nil else { returnError = error; return }
                    }
                }
            }
        }
    }
}
