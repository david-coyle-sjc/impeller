//
//  Repository.swift
//  Impeller
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

public protocol LocalRepository: ReadRepository, WriteRepository {
    func commit<T:Storable>(_ value: inout T, context: Any?)
    func delete<T:Storable>(_ value: inout T)
}


public protocol ReadRepository: class {
    func read<T:StorablePrimitive>(_ key:String) -> T?
    func read<T:StorablePrimitive>(optionalFor key:String) -> T??
    func read<T:StorablePrimitive>(_ key:String) -> [T]?
    func read<T:Storable>(_ key:String) -> T?
    func read<T:Storable>(optionalFor key:String) -> T??
    func read<T:Storable>(_ key:String) -> [T]?
}


public protocol WriteRepository: class {
    func write<T:StorablePrimitive>(_ value:T, for key:String)
    func write<T:StorablePrimitive>(_ optionalValue:T?, for key:String)
    func write<T:StorablePrimitive>(_ values:[T], for key:String)
    func write<T:Storable>(_ value:inout T, for key:String)
    func write<T:Storable>(_ optionalValue:inout T?, for key:String)
    func write<T:Storable>(_ values:inout [T], for key:String)
}
