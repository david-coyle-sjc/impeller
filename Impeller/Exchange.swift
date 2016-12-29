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
    
    func fetchValueTrees(forChangesSince cursor: Cursor?, completionHandler completion: @escaping (Error?, [ValueTree], Cursor?)->Void)
    func assimilate(_ ValueTrees: [ValueTree], completionHandler completion: @escaping CompletionHandler)
    
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
        var returnError: Error?
        
        // Join group for each exchangable in outer loop. 
        // Avoid race conditions by doing this before starting loop.
        for e1 in exchangables { group.enter() }
        
        // When group is complete, call completion
        group.notify(queue: DispatchQueue.main) {
            completion?(returnError)
        }
        
        for e1 in exchangables {
            let uniqueIdentifier = e1.uniqueIdentifier
            let c1 = cursor(forExchangableIdentifiedBy: uniqueIdentifier)
            e1.fetchValueTrees(forChangesSince: c1) {
                error, dictionaries, newCursor in
                
                defer { group.leave() }
                guard returnError == nil else { return }
                guard error == nil else { returnError = error; return }
                
                let assimilateGroup = DispatchGroup()
                
                // Join groups for each other exchangable.
                for e2 in self.exchangables {
                    guard e1 !== e2 else { continue }
                    group.enter()
                    assimilateGroup.enter()
                }
                
                // Save cursor if all stores successfully assimilate data
                assimilateGroup.notify(queue: DispatchQueue.main) {
                    guard returnError == nil else { return }
                    self.save(newCursor, forExchangableIdentifiedBy: uniqueIdentifier)
                }
                
                for e2 in self.exchangables {
                    guard e1 !== e2 else { continue }
                    e2.assimilate(dictionaries) {
                        error in
                        
                        defer { group.leave() }
                        defer { assimilateGroup.leave() }

                        guard returnError == nil else { return }
                        guard error == nil else { returnError = error; return }
                    }
                }
            }
        }
    }
}
