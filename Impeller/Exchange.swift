//
//  Exchange.swift
//  Impeller
//
//  Created by Drew McCormack on 11/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public class Exchange {
    public let exchangables: [Exchangable]
    public let pathForSavedState: String?
    
    public init(coupling exchangables: [Exchangable], pathForSavedState: String?) {
        precondition(exchangables.count > 1)
        self.exchangables = exchangables
        self.pathForSavedState = pathForSavedState
    }
    
    private func cursor(forExchangableIdentifiedBy identifier: UniqueIdentifier) -> Cursor? {
        return nil
    }
    
    private func save(_ cursor: Cursor, forExchangableIdentifiedBy identifier: UniqueIdentifier) {
    }
    
    public func exchange(completionHandler completion:CompletionHandler?) {
        let group = DispatchGroup()
        var returnError: Error?
        group.notify(queue: DispatchQueue.main) {
            completion?(returnError)
        }
        
        for e1 in exchangables {
            let uniqueIdentifier = e1.uniqueIdentifier
            let c1 = cursor(forExchangableIdentifiedBy: uniqueIdentifier)
            
            group.enter()
            e1.fetchValueTrees(forChangesSince: c1) {
                error, dictionaries, newCursor in
                defer { group.leave() }
                guard returnError == nil else { return }
                guard error == nil else { returnError = error; return }
                
                let assimilateGroup = DispatchGroup()
                assimilateGroup.notify(queue: DispatchQueue.main) {
                    self.save(newCursor, forExchangableIdentifiedBy: uniqueIdentifier)
                }
                
                for e2 in exchangables {
                    guard e1 !== e2 else { continue }
                    
                    group.enter()
                    assimilateGroup.enter()

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
