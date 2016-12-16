//
//  Storage.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public typealias Storage = StorageSource & StorageSink


public protocol StorageSource: class {
    
    func value<T:StorablePrimitive>(for key:String) -> T?
    func value<T:Storable>(for key:String) -> T?
    func values<T:StorablePrimitive>(for key:String) -> [T]
    func values<T:Storable>(for key:String) -> [T]
    
}


public protocol StorageSink: class {

    func store<T:StorablePrimitive>(_ value:T, for key:String)
    func store<T:StorablePrimitive>(_ value:T?, for key:String)
    func store<T:StorablePrimitive>(_ values:[T], for key:String)
    func store<T:Storable>(_ value:inout T, for key:String)
    func store<T:Storable>(_ value:inout T?, for key:String)
    func store<T:Storable>(_ values:inout [T], for key:String)
    
}


public protocol Cursor {
    var data: Data { get set }
}


public protocol Exchangable: class {

    var uniqueIdentifier: UniqueIdentifier { get }
    
    func fetchValueTrees(forChangesSince cursor: Cursor?, completionHandler completion: (Error?, [ValueTree], Cursor)->Void)
    func assimilate(_ ValueTrees: [ValueTree], completionHandler completion: CompletionHandler?)

}
