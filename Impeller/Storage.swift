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
    func optionalValue<T:StorablePrimitive>(for key:String) -> T??
    func values<T:StorablePrimitive>(for key:String) -> [T]?
    func value<T:Storable>(for key:String) -> T?
    func optionalValue<T:Storable>(for key:String) -> T??
    func values<T:Storable>(for key:String) -> [T]?
    
}


public protocol StorageSink: class {
    
    func save<T:Storable>(_ value: inout T, context: Any?)

    func store<T:StorablePrimitive>(_ value:T, for key:String)
    func store<T:StorablePrimitive>(_ optionalValue:T?, for key:String)
    func store<T:StorablePrimitive>(_ values:[T], for key:String)
    func store<T:Storable>(_ value:inout T, for key:String)
    func store<T:Storable>(_ optionalValue:inout T?, for key:String)
    func store<T:Storable>(_ values:inout [T], for key:String)
    
}
