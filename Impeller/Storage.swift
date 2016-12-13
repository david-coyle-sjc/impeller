//
//  Storage.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public protocol Storage : class {
    
    static var storagbleTypes: [Storable.Type] { get }
    
    func value<T:StorablePrimitive>(for key:String) -> T?
    func value<T:Storable>(for key:String) -> T?
    func values<T:StorablePrimitive>(for key:String) -> [T]
    func values<T:Storable>(for key:String) -> [T]
    
    func store<T:StorablePrimitive>(_ value:T, for key:String)
    func store<T:StorablePrimitive>(_ value:T?, for key:String)
    func store<T:StorablePrimitive>(_ values:[T], for key:String)
    func store<T:Storable>(_ value:inout T, for key:String)
    func store<T:Storable>(_ value:inout T?, for key:String)
    func store<T:Storable>(_ values:inout [T], for key:String)
    
}


protocol ExchangableStorage : class {
    
    
}